# frozen_string_literal: true

require "rails_helper"
require_relative "../training_dashboard/manage_training_steps"

RSpec.describe "Update participants details", js: true do
  include ManageTrainingSteps

  before do
    given_there_is_a_school_that_has_chosen_fip_for_2021_and_partnered
    and_i_am_signed_in_as_an_induction_coordinator
    and_i_have_added_an_ect
    when_i_click_on_add_your_early_career_teacher_and_mentor_details
    then_i_am_taken_to_roles_page
    when_i_click_on_continue
    then_i_am_taken_to_your_ect_and_mentors_page
    and_i_have_added_a_mentor
  end

  scenario "Induction tutor can change ECT / mentor name from check details page" do
    when_i_click_on_add_ect
    then_i_am_taken_to_add_ect_name_page

    when_i_add_ect_or_mentor_name
    when_i_click_on_continue
    then_i_am_taken_to_add_ect_or_mentor_email_page

    when_i_add_ect_or_mentor_email
    when_i_click_on_continue
    when_i_choose_assign_mentor_later
    when_i_click_on_continue
    then_i_am_taken_to_check_details_page

    when_i_click_on_change_name
    then_i_am_taken_to_add_ect_name_page

    when_i_add_ect_or_mentor_updated_name
    when_i_click_on_continue
    then_i_am_taken_to_add_ect_or_mentor_updated_email_page

    when_i_click_on_continue
    when_i_choose_assign_mentor_later
    when_i_click_on_continue
    then_i_am_taken_to_check_details_page
    then_i_can_view_updated_name
  end

  scenario "Induction tutor can change ECT / mentor email from check details page" do
    when_i_click_on_add_ect
    then_i_am_taken_to_add_ect_name_page

    when_i_add_ect_or_mentor_name
    when_i_click_on_continue
    then_i_am_taken_to_add_ect_or_mentor_email_page

    when_i_add_ect_or_mentor_email
    when_i_click_on_continue
    when_i_choose_assign_mentor_later
    when_i_click_on_continue
    then_i_am_taken_to_check_details_page

    when_i_click_on_change_email
    then_i_am_taken_to_add_ect_or_mentor_email_page

    when_i_add_ect_or_mentor_updated_email
    when_i_click_on_continue
    when_i_choose_assign_mentor_later
    when_i_click_on_continue
    then_i_am_taken_to_check_details_page
    then_i_can_view_updated_email
  end

  scenario "Induction tutor can change ECTs mentor from check details page" do
    when_i_click_on_add_ect
    when_i_click_on_continue
    then_i_am_taken_to_add_ect_name_page

    when_i_add_ect_or_mentor_name
    when_i_click_on_continue
    then_i_am_taken_to_add_ect_or_mentor_email_page

    when_i_add_ect_or_mentor_email
    when_i_click_on_continue
    then_i_am_taken_to_add_mentor_page
    then_the_page_should_be_accessible
    then_percy_should_be_sent_a_snapshot_named "Induction tutor chooses mentor for ECT"

    when_i_choose_a_mentor
    when_i_click_on_continue
    then_i_am_taken_to_check_details_page
    then_i_can_view_mentor_name

    when_i_click_on_change_mentor
    then_i_am_taken_to_add_mentor_page

    when_i_choose_assign_mentor_later
    when_i_click_on_continue
    then_i_am_taken_to_check_details_page
    then_i_can_view_assign_mentor_later_status
  end
end
