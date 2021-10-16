# frozen_string_literal: true

RSpec.describe Schools::Participants::Status, type: :view_component do
  component { described_class.new(participant_profile: profile) }

  context "when an email has been sent" do
    let(:profile) { create(:participant_profile, :ecf, :email_sent) }

    it "displayed the details required content" do
      expect(rendered).to have_content I18n.t "schools.participants.status.details_required.header"
      I18n.t("schools.participants.status.details_required.content").each do |content|
        expect(rendered).to have_content content
      end
    end
  end

  context "when an email bounced" do
    let(:profile) { create(:participant_profile, :ecf, :email_bounced) }

    it "displays the request for details failed content" do
      expect(rendered).to have_content I18n.t "schools.participants.status.request_for_details_failed.header"
      expect(rendered).to have_content I18n.t "schools.participants.status.request_for_details_failed.content"
    end
  end

  context "when no email has been sent" do
    let(:profile) { create(:participant_profile, :ecf) }

    it "displays the request to be sent content" do
      expect(rendered).to have_content I18n.t "schools.participants.status.request_to_be_sent.header"
      expect(rendered).to have_content I18n.t "schools.participants.status.request_to_be_sent.content"
    end
  end

  context "when the participant is doing FIP" do
    let(:school_cohort) { create(:school_cohort, :fip) }
    context "when the participant is an ECT" do
      let(:profile) { create(:participant_profile, :ect, school_cohort: school_cohort) }
      let!(:validation_data) { create(:ecf_participant_validation_data, participant_profile: profile) }

      context "when the participant is eligible" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :eligible, participant_profile: profile) }

        it "displays the eligible fip no partner content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip_no_partner.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip_no_partner.content"
        end

        context "when the school is in a partnership" do
          let!(:partnership) { create(:partnership, school: school_cohort.school, cohort: school_cohort.cohort) }

          it "displays the eligible fip content" do
            expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip.header"
            expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip.content"
          end
        end
      end

      context "when the participant has no QTS" do
        let!(:eligibility) { create(:ecf_participant_eligibility, qts: false, participant_profile: profile) }

        it "displays the fip ect no qts content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.fip_ect_no_qts.header"
          expect(rendered).to have_content (I18n.t "schools.participants.status.fip_ect_no_qts.content").first
        end
      end

      context "when the participant has a previous induction" do
        let!(:eligibility) { create(:ecf_participant_eligibility, previous_induction: true, participant_profile: profile) }

        it "displays the ineligible previous induction content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.ineligible_previous_induction.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.ineligible_previous_induction.content"
        end
      end

      context "when the participant has a TRN mismatch" do
        let!(:eligibility) { create(:ecf_participant_eligibility, different_trn: true, participant_profile: profile) }

        it "displays the checking eligibility content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.content"
        end
      end

      context "when the participant has active flags and manual check status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, active_flags: true, participant_profile: profile) }

        it "displays the checking eligibility content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.content"
        end
      end

      context "when the participant has active flags and ineligible status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :ineligible, active_flags: true, participant_profile: profile) }

        it "displays the ineligible flag content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.ineligible_flag.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.ineligible_flag.content"
        end
      end
    end

    context "when the participant is a mentor" do
      let(:profile) { create(:participant_profile, :mentor, school_cohort: school_cohort) }
      let!(:validation_data) { create(:ecf_participant_validation_data, participant_profile: profile) }

      context "when the participant is eligible" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :eligible, participant_profile: profile) }

        it "displays the eligible fip no partner content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip_no_partner.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip_no_partner.content"
        end

        context "when the school is in a partnership" do
          let!(:partnership) { create(:partnership, school: school_cohort.school, cohort: school_cohort.cohort) }
          it "displays the eligible fip content" do
            expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip.header"
            expect(rendered).to have_content I18n.t "schools.participants.status.eligible_fip.content"
          end
        end
      end

      context "when the participant has no QTS" do
        let!(:eligibility) { create(:ecf_participant_eligibility, qts: false, participant_profile: profile) }

        it "displays the checking eligibility content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.content"
        end
      end

      context "when the participant has a previous participation (ERO)" do
        let!(:eligibility) { create(:ecf_participant_eligibility, previous_participation: true, participant_profile: profile) }

        it "displays the ero mentor content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.ero_mentor.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.ero_mentor.content"
        end
      end

      context "when the participant has a TRN mismatch" do
        let!(:eligibility) { create(:ecf_participant_eligibility, different_trn: true, participant_profile: profile) }

        it "displays the checking eligibility content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.content"
        end
      end

      context "when the participant has active flags and manual check status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, active_flags: true, participant_profile: profile) }

        it "displays the checking eligibility content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.checking_eligibility.content"
        end
      end

      context "when the participant has active flags and ineligible status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :ineligible, active_flags: true, participant_profile: profile) }

        it "displays the ineligible flag content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.ineligible_flag.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.ineligible_flag.content"
        end
      end
    end
  end

  context "when the participant is doing CIP" do
    let(:school_cohort) { create(:school_cohort, :cip) }
    context "when the participant is an ECT" do
      let(:profile) { create(:participant_profile, :ect, school_cohort: school_cohort) }
      let!(:validation_data) { create(:ecf_participant_validation_data, participant_profile: profile) }

      context "when the participant is eligible" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :eligible, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has no QTS" do
        let!(:eligibility) { create(:ecf_participant_eligibility, qts: false, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has a previous induction" do
        let!(:eligibility) { create(:ecf_participant_eligibility, previous_induction: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has a TRN mismatch" do
        let!(:eligibility) { create(:ecf_participant_eligibility, different_trn: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has active flags and manual check status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, active_flags: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has active flags and ineligible status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :ineligible, active_flags: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end
    end

    context "when the participant is a mentor" do
      let(:profile) { create(:participant_profile, :mentor, school_cohort: school_cohort) }
      let!(:validation_data) { create(:ecf_participant_validation_data, participant_profile: profile) }

      context "when the participant is eligible" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :eligible, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has no QTS" do
        let!(:eligibility) { create(:ecf_participant_eligibility, qts: false, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has a previous participation (ERO)" do
        let!(:eligibility) { create(:ecf_participant_eligibility, previous_participation: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has a TRN mismatch" do
        let!(:eligibility) { create(:ecf_participant_eligibility, different_trn: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has active flags and manual check status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, active_flags: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end

      context "when the participant has active flags and ineligible status" do
        let!(:eligibility) { create(:ecf_participant_eligibility, :ineligible, active_flags: true, participant_profile: profile) }

        it "displays the eligible cip content" do
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.header"
          expect(rendered).to have_content I18n.t "schools.participants.status.eligible_cip.content"
        end
      end
    end
  end
end
