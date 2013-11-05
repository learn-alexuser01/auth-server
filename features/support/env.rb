require "httparty"
require "net/http/capture" # BUGBUG: httparty/capture should work; bug in HttpCapture I think...
require "cucumber/rest/steps/caching"
require "cucumber/rest/status"
require "ipaddress"
require "ipaddress/ipv4_loopback"
require "java_properties"
require "rack/test"
require "timecop"
require "thin"
require "blinkbox/zuul/server/email"

TEST_CONFIG = {}
TEST_CONFIG[:server] = URI.parse(ENV["AUTH_SERVER"] || "http://127.0.0.1:9393/")
TEST_CONFIG[:proxy] = ENV["PROXY_SERVER"] ? URI.parse(ENV["PROXY_SERVER"]) : nil
TEST_CONFIG[:in_proc] = if /^(false|no)$/i === ENV["IN_PROC"]
                          false
                        else
                          host = TEST_CONFIG[:server].host
                          if IPAddress.valid?(host)
                            host == "0.0.0.0" || IPAddress.parse(host).loopback?
                          else
                            /^localhost$/i === host
                          end
                        end
TEST_CONFIG[:local_network] = !(/\.com$/i === TEST_CONFIG[:server].host)
TEST_CONFIG[:debug] = /^(true|yes)$/i === ENV["DEBUG"]
TEST_CONFIG[:properties] = JavaProperties::Properties.new("./zuul.properties")

p TEST_CONFIG if TEST_CONFIG[:debug]

if TEST_CONFIG[:in_proc]
  require_relative "../../lib/blinkbox/zuul/server" 
  $server = Thin::Server.new(TEST_CONFIG[:server].host, TEST_CONFIG[:server].port, Blinkbox::Zuul::Server::App)
  Thread.new { $server.start }
  loop until $server.running?
end

# TODO: parametrise these
ELEVATION_CONFIG = {
  critical_timespan: (Blinkbox::Zuul::Server::RefreshToken::LifeSpan::CRITICAL_ELEVATION_LIFETIME_IN_SECONDS.to_i rescue 600),
  elevated_timespan: (Blinkbox::Zuul::Server::RefreshToken::LifeSpan::NORMAL_ELEVATION_LIFETIME_IN_SECONDS.to_i rescue 86400)
}

Before do
  $zuul = ZuulClient.new(TEST_CONFIG[:server], TEST_CONFIG[:proxy])
end

module KnowsAboutResponses
  def last_response
    HttpCapture::RESPONSES.last
  end
  def last_response_json
    MultiJson.load(last_response.body)
  end
end

module SleepsByTimeTravel
  def sleep(duration)
    Timecop.travel(duration)
  end
end

module SendsMessagesToFakeQueues
  module FakeEmail
    def self.included(base)
      base.instance_eval do
        @sent_messages = []
        def sent_messages
          @sent_messages
        end
        def enqueue(message)
          @sent_messages.push(message)
        end
      end
    end
  end  
  def self.extended(base)
    Blinkbox::Zuul::Server::Email.send(:include, FakeEmail)
  end
end

World(KnowsAboutResponses)
World(SleepsByTimeTravel) if TEST_CONFIG[:in_proc]
World(SendsMessagesToFakeQueues) if TEST_CONFIG[:in_proc]