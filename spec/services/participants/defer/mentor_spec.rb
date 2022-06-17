# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Defer::Mentor do
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let(:profile) { create(:mentor_participant_profile) }
  let(:user) { profile.user }
  let(:school) { profile.school_cohort.school }
  let(:cohort) { profile.school_cohort.cohort }
  let(:induction_programme) { create(:induction_programme, partnership:) }

  let!(:induction_record) do
    Induction::Enrol.call(participant_profile: profile, induction_programme:)
  end

  let!(:partnership) do
    create(
      :partnership,
      school:,
      lead_provider:,
      cohort:,
    )
  end

  subject do
    described_class.new(
      params: {
        participant_id: user.id,
        course_identifier: "ecf-mentor",
        cpd_lead_provider:,
        reason: "bereavement",
      },
    )
  end

  describe "#call" do
    it "updates profile training_status to deferred" do
      expect { subject.call }.to change { profile.reload.training_status }.from("active").to("deferred")
    end

    it "creates a ParticipantProfileState" do
      expect { subject.call }.to change { ParticipantProfileState.count }.by(1)
    end

    it "updates induction_record training_status" do
      expect { subject.call }.to change { induction_record.reload.training_status }.from("active").to("deferred")
    end

    context "when already deferred" do
      before do
        described_class.new(
          params: {
            participant_id: user.id,
            course_identifier: "ecf-mentor",
            cpd_lead_provider:,
            reason: "bereavement",
          },
        ).call # must be different instance from subject
      end

      it "raises an error and does not create a ParticipantProfileState" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { ParticipantProfileState.count }
      end
    end

    context "when status is withdrawn" do
      before do
        ParticipantProfileState.create!(participant_profile: profile, state: "withdrawn")
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
            course_identifier: "ecf-mentor",
            cpd_lead_provider:,
          },
        )
      end

      it "returns an error and does not update training_status" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { profile.reload.training_status }
      end
    end

    context "with a bogus reason" do
      subject do
        described_class.new(
          params: {
            participant_id: user.id,
            course_identifier: "ecf-mentor",
            cpd_lead_provider:,
            reason: "foo",
          },
        )
      end

      it "returns an error and does not update training_status" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing).and not_change { profile.reload.training_status }
      end
    end
  end
end
