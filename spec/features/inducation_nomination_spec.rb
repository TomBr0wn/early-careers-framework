# frozen_string_literal: true

require "rails_helper"
require "features/participants/participant_validation_steps"

RSpec.feature "Nominating tutors", :js do
  include ParticipantValidationSteps

  describe "When nominating an induction tutors with details that are not acceptable" do
    let(:cohort) { create(:cohort, start_year: "2021") }
    let(:school) { create(:school, name: "CIP School") }

    let!(:nomination_email) { create(:nomination_email, :email_address_already_used_for_another_school, token: "foo-bar-baz") }

    let(:teacher_profile) { create :teacher_profile }
    let(:ect_participant_profile) { create(:ect_participant_profile, teacher_profile: teacher_profile) }

    let(:different_user) { create(:user, email: "different-user-type@example.com") }
    let(:mailer) { double(SchoolMailer, deliver_later: nil) }

    before do
      create(:school_cohort, school: school, cohort: cohort, induction_programme_choice: "core_induction_programme")
      create(:ect_participant_profile, teacher_profile: create(:teacher_profile, user: different_user))
      allow(SchoolMailer).to receive(:nomination_confirmation_email).and_return(mailer)
    end

    it "shows error messages" do
      visit start_nominate_induction_coordinator_path(token: nomination_email.token)
      choose "Yes, (nominate someone to set up your induction for 2021/22)"
      click_on "Continue"

      click_on "Start"

      fill_in "Full name", with: "John Wick"
      fill_in "Work email address", with: "john-smith@example.com"
      click_on "Confirm"

      expect(page).to have_css("h1", text: "The name you entered does not match our records")

      and_the_page_should_be_accessible
      and_percy_should_be_sent_a_snapshot_named "Start nominations name different"

      click_on "Change the name"

      fill_in "Full name", with: "John Wick"
      fill_in "Work email address", with: different_user.email
      click_on "Confirm"

      expect(page).to have_css("h1", text: "The email you entered is used by another school")
      and_the_page_should_be_accessible
      and_percy_should_be_sent_a_snapshot_named "Start nominations email already used"

      click_on "Change email address"

      fill_in "Full name", with: "John Smith"
      fill_in "Work email address", with: "john-smith@example.com"
      click_on "Confirm"

      expect(page).to have_css(".govuk-panel--confirmation", text: "Induction tutor nominated")

      and_the_page_should_be_accessible
      and_percy_should_be_sent_a_snapshot_named "Start nominations email already used"

      expect(SchoolMailer)
        .to have_received(:nomination_confirmation_email)
        .with(
          sit_profile: User.find_by(email: "john-smith@example.com").induction_coordinator_profile,
          school: nomination_email.school,
          start_url: root_url(
            host: Rails.application.config.domain,
            **UTMService.email(:new_induction_tutor),
          ),
          step_by_step_url: step_by_step_url(
            host: Rails.application.config.domain,
            **UTMService.email(:new_induction_tutor),
          ),
        )
    end
  end
end
