# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Defer::NPQ, :with_default_schedules do
  let(:cpd_lead_provider)   { create(:cpd_lead_provider, :with_npq_lead_provider, :with_lead_provider) }
  let(:npq_lead_provider)   { cpd_lead_provider.npq_lead_provider }
  let!(:participant_profile) { create(:npq_participant_profile, npq_lead_provider:) }
  let(:user)                { participant_profile.user }
  let(:course_identifier) { participant_profile.npq_course.identifier }

  subject do
    described_class.new(
      params: {
        participant_id: user.id,
        course_identifier:,
        cpd_lead_provider:,
        reason: "bereavement",
      },
    )
  end

  describe "#call" do
    it "updates profile training_status to deferred" do
      expect { subject.call }.to change { participant_profile.reload.training_status }.from("active").to("deferred")
    end

    it "creates a ParticipantProfileState" do
      expect { subject.call }.to change { ParticipantProfileState.count }.by(1)
    end

    context "when already deferred" do
      before do
        described_class.new(
          params: {
            participant_id: user.id,
            course_identifier:,
            cpd_lead_provider:,
            reason: "bereavement",
          },
        ).call # must be different instance from subject
      end

      it "raises an error and does not create a ParticipantProfileState" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { ParticipantProfileState.count }
      end

      it "returns an error and does not update training_status" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { participant_profile.reload.training_status }
      end
    end

    context "when status is withdrawn" do
      before do
        # ParticipantProfileState.create!(participant_profile: profile, state: "withdrawn")
        profile.update!(status: "withdrawn")
      end

      xit "returns an error and does not update training_status" do
        # TODO: there is a gap and bug here
        # it should return a useful error
        # but throws an error as we scope to active profiles only and therefore never find the record
      end
    end

    context "without a reason" do
      subject do
        described_class.new(
          params: {
            participant_id: user.id,
            course_identifier:,
            cpd_lead_provider:,
          },
        )
      end

      it "returns an error and does not update training_status" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { participant_profile.reload.training_status }
      end
    end

    context "with a bogus reason" do
      subject do
        described_class.new(
          params: {
            participant_id: user.id,
            course_identifier:,
            cpd_lead_provider:,
            reason: "foo",
          },
        )
      end

      it "returns an error and does not update training_status" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { participant_profile.reload.training_status }
      end
    end

    context "with incorrect course" do
      let!(:participant_profile) { create(:ect, lead_provider: cpd_lead_provider.lead_provider) }
      let(:course_identifier) { "ecf-induction" }

      it "raises an error and does not create a ParticipantProfileState" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { ParticipantProfileState.count }
      end
    end
  end
end
