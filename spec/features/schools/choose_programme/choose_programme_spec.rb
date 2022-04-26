# frozen_string_literal: true

require "rails_helper"
require_relative "./choose_programme_steps"


RSpec.feature "Schools should be able to choose their programme", type: :feature, js: true, rutabaga: false do
  include ChooseProgrammeSteps

  before do
    freeze_time
    FeatureFlag.activate(:multiple_cohorts)
  end

  after do
    reset_time
  end

  scenario "A school set no ECTs in next academic year" do
    given_a_school_with_no_chosen_programme_for_next_academic_year
    and_i_am_signed_in_as_an_induction_coordinator

    # FIXME: open dashboard and click on start button when dashboard fixed
    when_I_start_programme_selection_for_next_cohort
    then_I_am_taken_to_ects_expected_in_next_academic_year_page
    and_the_page_should_be_accessible

    when_I_choose_no_ects
    and_I_click_continue
    then_I_am_taken_to_the_confirmation_page

    when_I_click_on_the_return_to_your_training_link
    then_I_am_taken_to_the_manage_your_training_page
  end
end
