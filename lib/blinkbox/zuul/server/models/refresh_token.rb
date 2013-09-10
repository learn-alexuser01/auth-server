module Blinkbox::Zuul::Server
  class RefreshToken < ActiveRecord::Base

    module Status
      VALID = "VALID"
      INVALID = "INVALID"
      NONE = "NONE"
    end

    module Elevation
      CRITICAL = "CRITICAL"
      ELEVATED = "ELEVATED"
      NONE = "NONE"
    end

    module LifeSpan
      TOKEN_LIFETIME_IN_DAYS = 90.0
      CRITICAL_ELEVATION_LIFETIME_IN_SECONDS = if ENV["ELEVATION_TIMESPAN"]
                                                 10.send(ENV["ELEVATION_TIMESPAN"])
                                               else
                                                 10.minutes
                                               end

      NORMAL_ELEVATION_LIFETIME_IN_SECONDS = 1.days
    end


    belongs_to :user
    belongs_to :client
    has_one :access_token

    validates :token, length: {within: 30..50}, uniqueness: true
    validates :expires_at, presence: true

    after_initialize :extend_lifetime
    after_create :extend_critical_elevation_lifetime

    def extend_lifetime
      self.expires_at = DateTime.now + LifeSpan::TOKEN_LIFETIME_IN_DAYS
    end

    def elevation
      if not self.critical_elevation_expires_at.past?
        Elevation::CRITICAL
      elsif not self.elevation_expires_at.past?
        Elevation::ELEVATED
      else
        Elevation::NONE
      end
    end

    def extend_elevation_time
      update_elevation

      case self.elevation
        when Elevation::CRITICAL
          self.critical_elevation_expires_at = DateTime.now + LifeSpan::CRITICAL_ELEVATION_LIFETIME_IN_SECONDS
        when Elevation::ELEVATED
          self.elevation_expires_at = DateTime.now + LifeSpan::NORMAL_ELEVATION_LIFETIME_IN_SECONDS
        else
      end

      self.save!

    end

    def update_elevation
      if self.expires_at.past?
        self.status = Status::INVALID
        self.save!
      end
    end

    private

    def extend_critical_elevation_lifetime
      self.status = RefreshToken::Status::VALID
      self.critical_elevation_expires_at = DateTime.now + LifeSpan::CRITICAL_ELEVATION_LIFETIME_IN_SECONDS
      self.elevation_expires_at = DateTime.now + LifeSpan::NORMAL_ELEVATION_LIFETIME_IN_SECONDS
      self.save!
    end
  end
end