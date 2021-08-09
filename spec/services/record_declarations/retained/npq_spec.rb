# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordDeclarations::Retained::NPQ do
  let(:cpd_lead_provider) { create(:cpd_lead_provider) }
  let(:another_lead_provider) { create(:cpd_lead_provider, name: "Unknown") }
  let(:npq_lead_provider) { create(:npq_lead_provider, cpd_lead_provider: cpd_lead_provider) }
  let(:npq_course) { create(:npq_course, identifier: "npq-leading-teaching") }
  let!(:npq_profile) do
    create(:npq_validation_data,
           npq_lead_provider: npq_lead_provider,
           npq_course: npq_course)
  end
  let(:induction_coordinator_profile) { create(:induction_coordinator_profile) }
  let(:params) do
    {
      raw_event: "{\"participant_id\":\"37b300a8-4e99-49f1-ae16-0235672b6708\",\"declaration_type\":\"retained-1\",\"declaration_date\":\"2021-06-21T08:57:31Z\",\"course_identifier\":\"npq-leading-teaching\"}",
      user_id: npq_profile.user_id,
      declaration_date: "2021-06-21T08:46:29Z",
      declaration_type: "retained-1",
      course_identifier: "npq-leading-teaching",
      lead_provider_from_token: another_lead_provider,
      evidence_held: "yes",
    }
  end

  let(:npq_params) do
    params.merge({ lead_provider_from_token: cpd_lead_provider })
  end
  let(:induction_coordinator_params) do
    npq_params.merge({ user_id: induction_coordinator_profile.user_id })
  end

  context "when sending event for an npq course" do
    it "creates a participant and profile declaration" do
      expect { described_class.call(npq_params) }.to change { ParticipantDeclaration.count }.by(1).and change { ProfileDeclaration.count }.by(1)
    end
  end

  context "when user is not a participant" do
    it "does not create a declaration record and raises ParameterMissing for an invalid user_id" do
      expect { described_class.call(induction_coordinator_params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when declaration type is invalid" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(params.merge(declaration_type: "invalid")) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when declaration type is valid for ECF but not NPQ" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(params.merge(declaration_type: "retained-3")) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when evidence held is invalid" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(params.merge(evidence_held: "invalid")) }.to raise_error(ActionController::ParameterMissing)
    end
  end
end
