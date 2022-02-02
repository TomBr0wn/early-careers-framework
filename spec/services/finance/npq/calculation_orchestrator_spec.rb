# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finance::NPQ::CalculationOrchestrator do
  let(:cpd_lead_provider) { create :cpd_lead_provider, :with_npq_lead_provider, name: "Contract Test Lead Provider" }
  let(:contract) { create(:npq_contract, npq_lead_provider: cpd_lead_provider.npq_lead_provider) }
  let(:npq_course) { create(:npq_course, identifier: contract.course_identifier) }
  let(:breakdown_summary) do
    {
      name: cpd_lead_provider.npq_lead_provider.name,
      recruitment_target: contract.recruitment_target,
      participants: 16,
      total_participants_paid: 16,
      total_participants_not_paid: nil, # TODO: we need to remove as no longer makes sense
      version: contract.version,
      course_identifier: contract.course_identifier,
    }
  end
  let(:service_fees) do
    {
      monthly: 72 * 0.4 * 800 / 19,
    }
  end
  let(:output_payments) do
    {
      participants: 16,
      per_participant: 800 * 0.6 / 3,
      subtotal: 16 * 800 * 0.6 / 3,
    }
  end

  let(:statement) do
    create(:npq_statement, cpd_lead_provider: cpd_lead_provider)
  end

  subject(:run_calculation) do
    described_class.new(
      statement: statement,
      contract: contract,
    ).call(event_type: :started)
  end

  context ".call" do
    context "normal operation" do
      before do
        timestamp = Date.new(2021, 10, 30)

        travel_to(timestamp) do
          FactoryBot.with_options cpd_lead_provider: cpd_lead_provider, course_identifier: contract.course_identifier, declaration_date: timestamp, created_at: timestamp, statement: statement do |factory|
            factory.create_list(:npq_participant_declaration, 3, :eligible)
            factory.create_list(:npq_participant_declaration, 2, :payable)
            factory.create_list(:npq_participant_declaration, 4, :submitted)
            # voided are not assigned to a statement
            # the above "fact" may change when we start dealing with clawbacks
            # factory.create_list(:npq_participant_declaration, 3, :voided)
            factory.create_list(:npq_participant_declaration, 7, :paid)
          end
        end
      end

      it "returns the total calculation" do
        expect(run_calculation[:breakdown_summary]).to eq(breakdown_summary)
        expect(run_calculation[:service_fees][:monthly]).to be_within(0.001).of(service_fees[:monthly])
        expect(run_calculation[:output_payments]).to eq(output_payments)
      end

      it "ignores declarations not associated to this statement" do
        create_list(:npq_participant_declaration, 5, :submitted, cpd_lead_provider: cpd_lead_provider, course_identifier: "other-course")
        expect(run_calculation[:breakdown_summary]).to eq(breakdown_summary)
        expect(run_calculation[:service_fees][:monthly]).to be_within(0.001).of(service_fees[:monthly])
        expect(run_calculation[:output_payments]).to eq(output_payments)
      end
    end
  end
end
