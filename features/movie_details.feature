Feature: View Movie Details
  As a user
  I want to view detailed information for a movie
  So I can learn more about it

  Background:
    Given the TMDb API is available
    And I am logged in as a user

  Scenario: Handle movie not found
    Given the movie with ID "999999" does not exist
    When I visit the movie details page for "999999"
    Then I should see an error message
