Feature: Search Movies
  As a user
  I want to search movies by title
  So I can find what I'm looking for

  Background:
    Given the TMDb API is available
    And I am logged in as a user

  Scenario: Search with empty query
    Given I am on the movies search page
    When I enter "" in the search field
    And I submit the search
    Then I should see a prompt to type something

  Scenario: Handle rate limit without cache
    Given the TMDb API rate limit is exceeded
    When I enter "NewMovie" in the search field
    And I submit the search
    Then I should see a rate limit message
