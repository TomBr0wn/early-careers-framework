# frozen_string_literal: true

RSpec.describe NPQApplication, type: :model do
  before { create(:schedule, name: "ECF September standard 2021") }

  it {
    is_expected.to define_enum_for(:headteacher_status).with_values(
      no: "no",
      yes_when_course_starts: "yes_when_course_starts",
      yes_in_first_two_years: "yes_in_first_two_years",
      yes_over_two_years: "yes_over_two_years",
    ).backed_by_column_of_type(:text)
  }

  describe "callbacks" do
    subject { create(:npq_application) }

    context "on creation" do
      it "fires NPQ::StreamBigQueryEnrollmentJob" do
        expect {
          subject
        }.to change(Delayed::Job, :count).by(1)
      end

      it "creates a NPQApplicationTemporary with matching attributes" do
        subject

        expect(NPQApplicationTemporary.find(subject.id).attributes).to eq subject.attributes
      end
    end

    context "when lead_provider_approval_status is modified" do
      it "fires NPQ::StreamBigQueryEnrollmentJob" do
        subject

        expect {
          subject.update(lead_provider_approval_status: "accepted")
        }.to change(Delayed::Job, :count).by(1)
      end

      it "updates a NPQApplicationTemporary with matching attributes" do
        subject
        subject.update!(lead_provider_approval_status: "accepted")

        expect(NPQApplicationTemporary.find(subject.id).attributes).to eq subject.attributes
      end
    end

    context "when record is touched" do
      it "does not fire NPQ::StreamBigQueryEnrollmentJob" do
        subject

        expect {
          subject.touch
        }.not_to change(Delayed::Job, :count)
      end

      it "updates a NPQApplicationTemporary with matching attributes" do
        subject
        subject.touch

        expect(NPQApplicationTemporary.find(subject.id).attributes).to eq subject.attributes
      end
    end
  end
end
