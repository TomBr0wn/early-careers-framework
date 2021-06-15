Feature: Lead Providers Guidance
  Scenario: Visiting the Lead Providers landing page
    Given I am on "the Lead Provider landing page" page
    And the page should be accessible
    And percy should be sent snapshot

  Scenario: Learning how to manage partnerships
    Given I am on "the Lead Provider landing page" page
    When I click on "link" containing "Learn to manage partnerships"
    Then I should be on "Partnership guidance" page
    And the page should be accessible
    And percy should be sent snapshot
