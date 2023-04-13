# frozen_string_literal: true

require "tempfile"

RSpec.describe Importers::CreateSchedule do
  describe "#call" do
    let!(:cohort) { Cohort.find_by(start_year: 2021) || create(:cohort, start_year: 2021) }
    let(:csv) { Tempfile.new("data.csv") }
    let(:path_to_csv) { csv.path }

    subject do
      described_class.new(path_to_csv:)
    end

    context "Invalid type" do
      before do
        csv.write "type,schedule-identifier,schedule-name,schedule-cohort-year,milestone-name,milestone-declaration-type,milestone-start-date,milestone-date,milestone-payment-date"
        csv.write "\n"
        csv.write "invalid,ecf-standard-september,ECF Standard September,2021,Output 1 - Participant Start,started,2021/09/01,2021/11/30,2021/11/30"
        csv.close
      end

      it "raises an error" do
        expect { subject.call }.to raise_error(ArgumentError, "Invalid schedule type")
      end
    end

    context "ECF" do
      let(:klass) { Finance::Schedule::ECF }

      before do
        csv.write "type,schedule-identifier,schedule-name,schedule-cohort-year,milestone-name,milestone-declaration-type,milestone-start-date,milestone-date,milestone-payment-date"
        csv.write "\n"
        csv.write "ecf_standard,ecf-standard-september,ECF Standard September,2021,Output 1 - Participant Start,started,2021/09/01,2021/11/30,2021/11/30"
        csv.close
      end

      context "new schedule" do
        it "creates new schedule" do
          expect(klass.count).to eql(0)
          subject.call
          expect(klass.count).to eql(1)

          schedule = klass.first
          expect(schedule.name).to eql("ECF Standard September")

          milestone = schedule.milestones.first
          expect(milestone.name).to eql("Output 1 - Participant Start")
          expect(milestone.declaration_type).to eql("started")
          expect(milestone.start_date).to eql("2021/09/01".to_date)
          expect(milestone.milestone_date).to eql("2021/11/30".to_date)
          expect(milestone.payment_date).to eql("2021/11/30".to_date)

          schedule_milestone = schedule.schedule_milestones.first
          expect(schedule_milestone.name).to eql("Output 1 - Participant Start")
          expect(schedule_milestone.declaration_type).to eql("started")
        end
      end

      context "existing schedule" do
        let!(:schedule) { create(:ecf_schedule, name: "New ECF name", schedule_identifier: "ecf-standard-september", cohort:) }

        it "updates the name" do
          expect(klass.count).to eql(1)
          expect(schedule.reload.name).to eql("New ECF name")
          subject.call
          expect(klass.count).to eql(1)
          expect(schedule.reload.name).to eql("ECF Standard September")
        end
      end
    end

    context "NPQ" do
      let(:klass) { Finance::Schedule::NPQLeadership }

      before do
        csv.write "type,schedule-identifier,schedule-name,schedule-cohort-year,milestone-name,milestone-declaration-type,milestone-start-date,milestone-date,milestone-payment-date"
        csv.write "\n"
        csv.write "npq_leadership,npq-leadership-autumn,NPQ Leadership Autumn,2021,Output 1 - Participant Start,started,01/11/2021,01/11/2021,01/11/2021"
        csv.close
      end

      context "new schedule" do
        it "creates new schedule" do
          expect(klass.count).to eql(0)
          subject.call
          expect(klass.count).to eql(1)

          schedule = klass.first
          expect(schedule.name).to eql("NPQ Leadership Autumn")

          milestone = schedule.milestones.first
          expect(milestone.name).to eql("Output 1 - Participant Start")
          expect(milestone.declaration_type).to eql("started")
          expect(milestone.start_date).to eql("01/11/2021".to_date)
          expect(milestone.milestone_date).to eql("01/11/2021".to_date)
          expect(milestone.payment_date).to eql("01/11/2021".to_date)

          schedule_milestone = schedule.schedule_milestones.first
          expect(schedule_milestone.name).to eql("Output 1 - Participant Start")
          expect(schedule_milestone.declaration_type).to eql("started")
        end
      end

      context "existing schedule" do
        let!(:schedule) { create(:npq_leadership_schedule, name: "New NPQ name", schedule_identifier: "npq-leadership-autumn", cohort:) }

        it "updates the name" do
          expect(schedule.type).to eql(klass.name)
          expect(klass.count).to eql(1)
          expect(schedule.reload.name).to eql("New NPQ name")
          subject.call
          expect(klass.count).to eql(1)
          expect(schedule.reload.name).to eql("NPQ Leadership Autumn")
        end
      end
    end
  end

  describe "#type_to_klass" do
    subject do
      described_class.new(path_to_csv: "test.csv")
    end

    it "returns correct schedule class for each type" do
      expect(subject.send(:type_to_klass, "npq_specialist")).to eql(Finance::Schedule::NPQSpecialist)
      expect(subject.send(:type_to_klass, "npq_leadership")).to eql(Finance::Schedule::NPQLeadership)
      expect(subject.send(:type_to_klass, "npq_aso")).to eql(Finance::Schedule::NPQSupport)
      expect(subject.send(:type_to_klass, "npq_ehco")).to eql(Finance::Schedule::NPQEhco)
      expect(subject.send(:type_to_klass, "ecf_standard")).to eql(Finance::Schedule::ECF)
      expect(subject.send(:type_to_klass, "ecf_reduced")).to eql(Finance::Schedule::ECF)
      expect(subject.send(:type_to_klass, "ecf_extended")).to eql(Finance::Schedule::ECF)
      expect(subject.send(:type_to_klass, "ecf_replacement")).to eql(Finance::Schedule::Mentor)
    end
  end
end
