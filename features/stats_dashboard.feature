Feature: Stats Dashboard
  As a user
  I want to view my movie watching statistics
  So I can track my viewing activity

  Background:
    Given the TMDb API is available
    And I am logged in as a user

  Scenario: View stats overview with logged movies
    Given I have logged movies
    When I visit the stats page
    Then I should see all overview metrics
    And I should see the total movies watched
    And I should see the total hours watched
    And I should see the total reviews written
    And I should see the total rewatches
    And I should see the genre breakdown

  Scenario: View stats overview with no logged movies
    Given I have no logged movies
    When I visit the stats page
    Then I should see an empty-state message
    And I should see a link to browse movies

  Scenario: Stats update after adding new log
    Given I have logged movies
    When I visit the stats page
    And I note the current total movies count
    And I add a new log entry
    And I refresh the stats page
    Then the totals should update accordingly

  Scenario: View top contributors
    Given I have logged movies with metadata
    When I visit the stats page
    Then I should see the top three genres
    And I should see my most-watched directors
    And I should see my most-watched actors

  Scenario: View top contributors with missing metadata
    Given I have logged movies without metadata
    When I visit the stats page
    Then I should see top genres if available
    And I should see a message for missing directors
    And I should see a message for missing actors

  Scenario: View trend charts with sufficient data
    Given I have enough log data for trends
    When I visit the stats page
    Then I should see the activity trend chart
    And I should see the rating trend chart
    And the charts should display data points


