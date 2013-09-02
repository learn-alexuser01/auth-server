require_relative "change_tracking"

class TestClient

  tracked_attr_accessor :name,
                        :model

  attr_accessor :id,
                :local_id,
                :secret

  def generate_details
    @name = "My Test Client"
    @model = "Test Device"
    self
  end

  def register(access_token)
    response = $zuul.register_client(self, access_token)
    if response.status == 200
      token_info = MultiJson.load(response.body)
      @name = token_info["client_name"]   # as it may have been generated by the server
      @model = token_info["client_model"] # as it may have been generated by the server
      @id = token_info["client_id"]
      @local_id = @id[/\d+$/]
      @secret = token_info["client_secret"]
    end
    response
  end

end