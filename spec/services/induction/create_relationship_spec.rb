# frozen_string_literal: true

RSpec.describe Induction::CreateRelationship do
  describe "#call" do
    let(:school_cohort) { create :school_cohort }
    let(:lead_provider) { create(:lead_provider) }
    let(:delivery_partner) { create(:delivery_partner) }

    subject(:service) { described_class }

    it "adds a new Partnership record" do
      expect {
        service.call(school_cohort:,
                     lead_provider:,
                     delivery_partner:)
      }.to change { school_cohort.school.partnerships.count }.by 1
    end

    it "sets the relationship flag on the Partnership" do
      service.call(school_cohort:,
                   lead_provider:,
                   delivery_partner:)

      expect(school_cohort.school.partnerships.last).to be_relationship
    end

    it "the Partnership doesn't have a challenge window" do
      service.call(school_cohort:,
                   lead_provider:,
                   delivery_partner:)

      expect(school_cohort.school.partnerships.last).not_to be_in_challenge_window
    end
  end
end
