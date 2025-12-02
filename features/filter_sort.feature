Feature: Filter and Sort Search Results
  As a user
  I want to filter and sort search results
  So I can find movies more easily

  Background:
    Given the TMDb API is available
    And I am logged in as a user

  Scenario: Filter by genre
    Given I have searched for "action"
    When I select "Action" from the genre filter
    And I apply the filter
    Then only movies with "Action" genre should appear

  Scenario: Filter by decade
    Given I have searched for "2010"
    When I select "2010s" from the decade filter
    And I apply the filter
    Then only movies from "2010s" should appear

  Scenario: Sort with no results
    Given I have no search results
    When I try to sort the results
    Then the empty state should remain unchanged
