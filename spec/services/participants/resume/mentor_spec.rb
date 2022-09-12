# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Resume::Mentor, :with_default_schedules do
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let!(:participant_profile) { create(:mentor, :deferred, lead_provider:) }

  subject do
    described_class.new(
      params: {
        participant_id: participant_profile.user_id,
        course_identifier: "ecf-mentor",
        cpd_lead_provider:,
      },
    )
  end

  describe "#call" do
    it "updates the participant profile training_status to active" do
      expect { subject.call }.to change { participant_profile.reload.training_status }.from("deferred").to("active")
    end

    it "updates induction_record training_status to active" do
      expect { subject.call }.to change { participant_profile.induction_records.latest.training_status }.from("deferred").to("active")
    end

    it "creates a ParticipantProfileState" do
      expect { subject.call }.to change { ParticipantProfileState.count }.by(1)
    end

    context "when already active" do
      before do
        described_class.new(
          params: {
            participant_id: participant_profile.user_id,
            course_identifier: "ecf-mentor",
            cpd_lead_provider:,
          },
        ).call # must be different instance from subject
      end

      it "raises an error and does not create a ParticipantProfileState" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { ParticipantProfileState.count }
      end
    end

    context "when status is withdrawn" do
      before do
        ParticipantProfileState.create!(participant_profile:, state: "withdrawn")
        participant_profile.update!(status: "withdrawn")
      end

      xit "returns an error and does not update training_status" do
        # TODO: there is a gap and bug here
        # it should return a useful error but throws an error as we scope to
        # active participant profiles only and therefore never find the record
      end
    end

    context "with incorrect course" do
      let!(:participant_profile) { create(:ect, :deferred, lead_provider:) }

      it "raises an error and does not create a ParticipantProfileState" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { ParticipantProfileState.count }
      end
    end
  end
end
