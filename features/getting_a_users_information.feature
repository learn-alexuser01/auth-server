@users @user_info
Feature: Getting a user's information
  As a user
  I want to be able to get information about myself
  So that I can check whether my details are up to date

  Background:
    Given I have registered an account

  @smoke
  Scenario: Getting user information
    Given I have a critically elevated access token
    When I request user information for myself
    Then the response contains complete user information matching my details
    And it is not cacheable
    And the critical elevation got extended

  Scenario: Trying to get user information without authorisation
    When I request user information for myself, without my access token
    Then the request fails because I am unauthorised
    And the response does not include any error information

  Scenario: Trying to get user information for a nonexistent user
    When I request user information for a nonexistent user
    Then the request fails because the user was not found

  Scenario: Trying to get user information for a different user
    For security reasons we don't distinguish between a user that doesn't exist and a user that
    does exist but is not the current user. In either case we say it was not found.

    Given another user has registered an account
    When I request user information for the other user
    Then the request fails because the user was not found

  @extremely_slow
  Scenario Outline: Access personal information outside critical elevation period
    Given I have <elevation_level> access token
    When I request user information for myself
    Then the request fails because I am unauthorised
    And the response includes low elevation level information

    Examples:
      | elevation_level |
      | a non-elevated  |
      | an elevated     |
