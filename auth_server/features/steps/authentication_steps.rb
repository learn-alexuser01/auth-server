
Given(/^I have authenticated with my email address and password$/) do
  provide_user_credentials
  submit_authentication_request
  check_response_tokens
end

Given(/^I have provided my email address$/) do
  provide_user_credentials
  @credentials.delete("password")
end

Given(/^I have provided my email address and password$/) do
  provide_user_credentials
end

Given(/^I have provided my email address, password and client credentials$/) do
  provide_user_credentials
  provide_client_credentials
end

Given(/^the email address is different from the one I used to register$/) do
  @credentials["username"] = random_email
end

Given(/^I have not provided my (password|client secret)$/) do |name|
  @credentials.delete(oauth_param_name(name))
end

Given(/^I have provided an incorrect (password|client secret)$/) do |name|
  @credentials[oauth_param_name(name)] = random_password
end

Given(/^I have provided another user's client credentials$/) do
  register_new_user
  register_new_client
  provide_client_credentials
end

Given(/^I have (not )?provided my refresh token$/) do |no_token|
  @credentials = { "grant_type" => "refresh_token" }
  @credentials["refresh_token"] = @oauth_response["refresh_token"] unless no_token
end

Given(/^I have provided an incorrect refresh token$/) do  
  @credentials = { "grant_type" => "refresh_token", "refresh_token" => random_password }
end

When(/^I submit the (?:authentication|access token refresh) request$/) do
  submit_authentication_request
end

Then(/^the response indicates that my (?:credentials are|refresh token is) incorrect$/) do
  @response.code.to_i.should == 400
  @response_json = MultiJson.load(@response.body)
  @response_json["error"].should == "invalid_grant"
end