Feature: See Similar Movies
  As a user
  I want to see similar movies
  So I can discover related films

  Background:
    Given the TMDb API is available
    And I am logged in as a user

  Scenario: View similar movies successfully
    Given I am viewing the movie details page for "Inception"
    When I scroll to the similar movies section
    Then I should see recommended titles

  Scenario: Handle API failure for similar movies
    Given I am viewing the movie details page for "Inception"
    And the TMDb API fails for similar movies
    When I scroll to the similar movies section
    Then I should see an error placeholder
