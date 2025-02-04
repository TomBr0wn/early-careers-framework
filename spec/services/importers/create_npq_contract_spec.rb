# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::CreateNPQContract do
  let(:csv) { Tempfile.new("data.csv") }
  let(:path_to_csv) { csv.path }
  let(:set_to_latest_version) { false }

  let!(:cpd_lead_provider) { create(:cpd_lead_provider, :with_npq_lead_provider, name: "Ambition Institute") }
  let!(:npq_lead_provider) { cpd_lead_provider.npq_lead_provider }
  let!(:cohort) { FactoryBot.create :cohort }
  let!(:npq_specialist_course) { create(:npq_specialist_course, name: "NPQ Leading Teaching (npq-leading-teaching)", identifier: "npq-leading-teaching") }
  let!(:npq_leadership_course) { create(:npq_leadership_course, name: "NPQ for Headship (npq-headship)", identifier: "npq-headship") }
  let!(:npq_ehco_course)       { create(:npq_ehco_course, name: "The Early Headship Coaching Offer", identifier: "npq-early-headship-coaching-offer") }

  subject { described_class.new(path_to_csv:, set_to_latest_version:) }

  describe "#call" do
    context "when headers are incorrect" do
      before do
        csv.write "foo,bar"
        csv.write "\n"
        csv.close
      end

      it "throws an error" do
        expect { subject.call }.to raise_error(NameError)
      end
    end

    context "when new contract" do
      before do
        csv.write "provider_name,cohort_year,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course"
        csv.write "\n"
        csv.write "Ambition Institute,#{cohort.start_year},npq-leading-teaching,123,456.78,13,TRUE"
        csv.write "\n"
        csv.close
      end

      it "creates a new contract with correct values" do
        expect { subject.call }.to change { NPQContract.count }.by(1)

        contract = NPQContract.last

        expect(contract.npq_lead_provider).to eql(npq_lead_provider)
        expect(contract.recruitment_target).to eql(123)
        expect(contract.course_identifier).to eql(npq_specialist_course.identifier)
        expect(contract.service_fee_installments).to eql(13)
        expect(contract.service_fee_percentage).to eql(40)
        expect(contract.output_payment_percentage).to eql(60)
        expect(contract.per_participant).to eql(456.78)
        expect(contract.number_of_payment_periods).to eql(3)
        expect(contract.cohort).to eql(cohort)
        expect(contract.version).to eql("0.0.1")
        expect(contract.monthly_service_fee).to eql(0.0)
        expect(contract.special_course).to eql(true)
      end
    end

    context "when new version" do
      let(:set_to_latest_version) { true }
      let(:contract_version) { "0.0.3" }
      let!(:statement) { create(:npq_statement, cpd_lead_provider:, cohort:, contract_version:) }

      before do
        csv.write "provider_name,cohort_year,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course"
        csv.write "\n"
        csv.write "Ambition Institute,#{cohort.start_year},npq-leading-teaching,123,456.78,13,false"
        csv.write "\n"
        csv.close
      end

      it "creates/update contract with new version" do
        expect { subject.call }.to change { NPQContract.count }.by(1)

        contract = NPQContract.last

        expect(contract.npq_lead_provider).to eql(npq_lead_provider)
        expect(contract.recruitment_target).to eql(123)
        expect(contract.course_identifier).to eql(npq_specialist_course.identifier)
        expect(contract.service_fee_installments).to eql(13)
        expect(contract.service_fee_percentage).to eql(40)
        expect(contract.output_payment_percentage).to eql(60)
        expect(contract.per_participant).to eql(456.78)
        expect(contract.number_of_payment_periods).to eql(3)
        expect(contract.cohort).to eql(cohort)
        expect(contract.version).to eql(contract_version)
        expect(contract.special_course).to eql(false)
      end
    end

    context "code is run more than once" do
      before do
        csv.write "provider_name,cohort_year,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course"
        csv.write "\n"
        csv.write "Ambition Institute,#{cohort.start_year},npq-leading-teaching,123,456.78,13"
        csv.write "\n"
        csv.close
      end

      it "is idempotent" do
        expect {
          subject.call
          subject.call
        }.to change { NPQContract.count }.by(1)
      end
    end

    context "when existing contract" do
      before do
        csv.write "provider_name,cohort_year,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course"
        csv.write "\n"
        csv.write "Ambition Institute,#{cohort.start_year},npq-leading-teaching,123,456.78,13,TRUE"
        csv.write "\n"
        csv.close

        NPQContract.create!(
          npq_lead_provider:,
          cohort:,
          course_identifier: npq_specialist_course.identifier,
          recruitment_target: 100,
          per_participant: 100,
          service_fee_installments: 100,
          number_of_payment_periods: 100,
          special_course: false,
        )
      end

      it "updates the contract" do
        expect {
          subject.call
        }.not_to change { NPQContract.count }

        contract = NPQContract.last

        expect(contract.recruitment_target).to eql(123)
        expect(contract.per_participant).to eql(456.78)
        expect(contract.service_fee_installments).to eql(13)
        expect(contract.number_of_payment_periods).to eql(3)
        expect(contract.special_course).to eql(true)
      end
    end

    context "when a leadership course" do
      before do
        csv.write "provider_name,cohort_year,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course"
        csv.write "\n"
        csv.write "Ambition Institute,#{cohort.start_year},npq-headship,321,654.87,14,true"
        csv.write "\n"
        csv.close
      end

      it "creates a new contract with correct values" do
        expect { subject.call }.to change { NPQContract.count }.by(1)

        contract = NPQContract.last

        expect(contract.npq_lead_provider).to eql(npq_lead_provider)
        expect(contract.recruitment_target).to eql(321)
        expect(contract.course_identifier).to eql(npq_leadership_course.identifier)
        expect(contract.service_fee_installments).to eql(14)
        expect(contract.service_fee_percentage).to eql(40)
        expect(contract.output_payment_percentage).to eql(60)
        expect(contract.per_participant).to eql(654.87)
        expect(contract.number_of_payment_periods).to eql(4)
        expect(contract.cohort).to eql(cohort)
        expect(contract.special_course).to eql(true)
      end
    end

    context "when EHCO course" do
      before do
        csv.write "provider_name,cohort_year,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course"
        csv.write "\n"
        csv.write "Ambition Institute,#{cohort.start_year},npq-early-headship-coaching-offer,789,111.22,15,FALSE"
        csv.write "\n"
        csv.close
      end

      it "creates a new contract with correct values" do
        expect { subject.call }.to change { NPQContract.count }.by(1)

        contract = NPQContract.last

        expect(contract.npq_lead_provider).to eql(npq_lead_provider)
        expect(contract.recruitment_target).to eql(789)
        expect(contract.course_identifier).to eql(npq_ehco_course.identifier)
        expect(contract.service_fee_installments).to eql(15)
        expect(contract.service_fee_percentage).to eql(0)
        expect(contract.output_payment_percentage).to eql(100)
        expect(contract.per_participant).to eql(111.22)
        expect(contract.number_of_payment_periods).to eql(4)
        expect(contract.cohort).to eql(cohort)
        expect(contract.special_course).to eql(false)
      end
    end
  end
end
