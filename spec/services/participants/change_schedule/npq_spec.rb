# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::ChangeSchedule::NPQ do
  describe "validations" do
    context "when null schedule_identifier given" do
      let(:cpd_lead_provider) { profile.npq_application.npq_lead_provider.cpd_lead_provider }
      let(:user) { profile.user }
      let(:profile) { create(:npq_participant_profile) }

      subject do
        described_class.new(params: {
          schedule_identifier: nil,
          participant_id: user.id,
          course_identifier: profile.npq_course.identifier,
          cpd_lead_provider:,
        })
      end

      before do
        create(:schedule, name: "Schedule with no alias")
      end

      it "should have an error" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context "when changing to schedule suitable for the course" do
      let(:cpd_lead_provider) { profile.npq_application.npq_lead_provider.cpd_lead_provider }
      let(:user) { profile.user }
      let(:profile) { create(:npq_participant_profile) }
      let(:schedule) do
        case profile.npq_course.identifier
        when *Finance::Schedule::NPQSpecialist::IDENTIFIERS
          create(:npq_specialist_schedule)
        when *Finance::Schedule::NPQLeadership::IDENTIFIERS
          create(:npq_leadership_schedule)
        when *Finance::Schedule::NPQSupport::IDENTIFIERS
          create(:npq_aso_schedule)
        when *Finance::Schedule::NPQEhco::IDENTIFIERS
          create(:npq_ehco_schedule)
        end
      end

      subject do
        described_class.new(params: {
          schedule_identifier: schedule.schedule_identifier,
          participant_id: user.id,
          course_identifier: profile.npq_course.identifier,
          cpd_lead_provider:,
        })
      end

      it "should not have an error" do
        expect { subject.call }.not_to raise_error
      end
    end

    context "when changing to schedule not suitable for the course" do
      let(:cpd_lead_provider) { profile.npq_application.npq_lead_provider.cpd_lead_provider }
      let(:user) { profile.user }
      let(:profile) { create(:npq_participant_profile) }
      let(:schedule) { create(:ecf_mentor_schedule) }

      subject do
        described_class.new(params: {
          schedule_identifier: schedule.schedule_identifier,
          participant_id: user.id,
          course_identifier: profile.npq_course.identifier,
          cpd_lead_provider:,
        })
      end

      it "should have an error" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "changing to a soft schedules with previous declarations" do
    let(:cpd_lead_provider) { profile.npq_application.npq_lead_provider.cpd_lead_provider }
    let(:cohort) { create(:cohort) }
    let(:schedule) do
      case profile.npq_course.identifier
      when *Finance::Schedule::NPQSpecialist::IDENTIFIERS
        create(:npq_specialist_schedule, schedule_identifier: "soft-schedule")
      when *Finance::Schedule::NPQLeadership::IDENTIFIERS
        create(:npq_leadership_schedule, schedule_identifier: "soft-schedule")
      when *Finance::Schedule::NPQSupport::IDENTIFIERS
        create(:npq_aso_schedule, schedule_identifier: "soft-schedule")
      when *Finance::Schedule::NPQEhco::IDENTIFIERS
        create(:npq_ehco_schedule, schedule_identifier: "soft-schedule")
      end
    end
    let!(:started_milestone) { create(:milestone, :started, :soft_milestone, schedule:) }
    let(:user) { profile.user }
    let(:profile) { create(:npq_participant_profile) }
    let!(:declaration) do
      create(:npq_participant_declaration,
             user:,
             participant_profile: profile,
             course_identifier: profile.npq_course.identifier)
    end

    subject do
      described_class.new(params: {
        schedule_identifier: schedule.schedule_identifier,
        participant_id: user.id,
        course_identifier: profile.npq_course.identifier,
        cpd_lead_provider:,
        cohort: schedule.cohort.start_year,
      })
    end

    it "changes schedule" do
      expect {
        subject.call
      }.to change { profile.reload.schedule.schedule_identifier }.from(profile.schedule.schedule_identifier).to("soft-schedule")
    end
  end
end
