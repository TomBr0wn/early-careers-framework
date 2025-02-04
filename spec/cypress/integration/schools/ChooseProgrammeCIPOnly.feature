Feature: Induction tutors choosing programmes - CIP only

  Background:
    Given scenario "cip_only_school" has been run
    Given cohort was created as "current"
    And I am logged in as an induction coordinator for created school
    Then I should be on "choose programme" page

  Scenario: Choosing the school funded fip programme
    When I click on "use a training provider funded by your school radio button"
    And I click the submit button
    Then I should be on "choose programme confirm" page
    And the page should be accessible

    When I click the submit button
    Then I should be on "have you appointed an appropriate body" page

    When I click on "No" label
    And I click the submit button
    Then I should be on "choose programme success" page
    And the page should be accessible
