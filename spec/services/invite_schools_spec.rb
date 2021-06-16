# frozen_string_literal: true

require "rails_helper"

RSpec.describe InviteSchools do
  subject(:invite_schools) { described_class.new }
  let(:primary_contact_email) { Faker::Internet.email }
  let(:secondary_contact_email) { Faker::Internet.email }

  let(:school) do
    create(
      :school,
      primary_contact_email: primary_contact_email,
      secondary_contact_email: secondary_contact_email,
    )
  end

  before(:all) do
    RSpec::Mocks.configuration.verify_partial_doubles = false
  end

  before(:each) do
    allow_any_instance_of(Mail::TestMailer).to receive_message_chain(:response, :id) { "notify_id" }
  end

  after(:all) do
    RSpec::Mocks.configuration.verify_partial_doubles = true
  end

  describe "#run" do
    let(:nomination_email) { school.nomination_emails.last }

    it "creates a record for the nomination email" do
      expect {
        invite_schools.run [school.urn]
      }.to change { school.nomination_emails.count }.by 1
    end

    it "creates a nomination email with the correct fields" do
      invite_schools.run [school.urn]
      expect(nomination_email.sent_to).to eq school.primary_contact_email
      expect(nomination_email.sent_at).to be_present
      expect(nomination_email.token).to be_present
    end

    it "sends the nomination email" do
      travel_to Time.utc("2000-1-1")
      expect(SchoolMailer).to receive(:nomination_email).with(
        hash_including(
          school_name: String,
          nomination_url: String,
          recipient: school.primary_contact_email,
          expiry_date: "22/01/2000",
        ),
      ).and_call_original

      invite_schools.run [school.urn]
    end

    it "sets the notify id on the nomination email record" do
      invite_schools.run [school.urn]
      expect(nomination_email.notify_id).to eq "notify_id"
    end

    context "when school primary contact email is empty" do
      let(:primary_contact_email) { "" }

      it "sends the nomination email to the secondary contact" do
        expect(SchoolMailer).to receive(:nomination_email).with(
          hash_including(
            school_name: String,
            nomination_url: String,
            recipient: school.secondary_contact_email,
          ),
        ).and_call_original

        invite_schools.run [school.urn]
      end
    end

    context "when there is an error creating the nomination email" do
      let(:primary_contact_email) { nil }
      let(:secondary_contact_email) { nil }
      let(:another_school) { create(:school) }

      it "skips to the next school_id" do
        invite_schools.run [school.urn, another_school.urn]
        expect(school.nomination_emails).to be_empty
        expect(another_school.nomination_emails).not_to be_empty
      end
    end
  end

  describe "#sent_email_recently?" do
    it "is false when the school has not been emailed" do
      expect(invite_schools.sent_email_recently?(school)).to eq false
    end

    context "when the school has been emailed more than 24 hours ago" do
      before do
        create(:nomination_email, school: school, sent_at: 25.hours.ago)
      end

      it "returns false" do
        expect(invite_schools.sent_email_recently?(school)).to eq false
      end
    end

    context "when the school has been emailed within the last 24 hours" do
      before do
        create(:nomination_email, school: school)
      end

      it "returns true" do
        expect(invite_schools.sent_email_recently?(school)).to eq true
      end
    end

    context "when the school has been emailed more than one" do
      before do
        create(:nomination_email, school: school, sent_at: 5.days.ago)
      end

      context "and have been emailed within the last 24 hours" do
        before do
          create(:nomination_email, school: school)
        end

        it "returns true" do
          expect(invite_schools.sent_email_recently?(school)).to eq true
        end
      end

      context "and the school has not been emailed within the last 24 hours" do
        before do
          create(:nomination_email, school: school, sent_at: 25.hours.ago)
        end

        it "returns false" do
          expect(invite_schools.sent_email_recently?(school)).to eq false
        end
      end
    end
  end

  describe "#send_chasers" do
    let!(:cohort) { create(:cohort, :current) }
    it "does not send emails to schools who have nominated tutors" do
      # Given there is a school with an induction coordinator
      create(:user, :induction_coordinator)
      expect(School.count).to eq 1
      expect(School.without_induction_coordinator.count).to eq 0

      expect(an_instance_of(InviteSchools)).not_to delay_execution_of(:create_and_send_nomination_email)
    end

    it "sends emails to all available addresses" do
      school = create(:school, primary_contact_email: "primary@example.com", secondary_contact_email: "secondary@example.com")
      AdditionalSchoolEmail.create!(school: school, email_address: "additional1@example.com")
      AdditionalSchoolEmail.create!(school: school, email_address: "additional2@example.com")

      invite_schools.send_chasers
      expect(an_instance_of(InviteSchools)).to delay_execution_of(:create_and_send_nomination_email).with("primary@example.com", school)
      expect(an_instance_of(InviteSchools)).to delay_execution_of(:create_and_send_nomination_email).with("secondary@example.com", school)
      expect(an_instance_of(InviteSchools)).to delay_execution_of(:create_and_send_nomination_email).with("additional1@example.com", school)
      expect(an_instance_of(InviteSchools)).to delay_execution_of(:create_and_send_nomination_email).with("additional2@example.com", school)
    end

    it "does not send emails to schools that are not eligible" do
      # Given an ineligible school
      create(:school, school_type_code: 56)
      expect(School.count).to eql 1
      expect(School.eligible.count).to eql 0

      expect(an_instance_of(InviteSchools)).not_to delay_execution_of(:create_and_send_nomination_email)
    end
  end

  describe "#invite_to_beta" do
    let!(:cohort) { create(:cohort, :current) }
    let(:induction_coordinator) { create(:user, :induction_coordinator) }
    let(:school) { induction_coordinator.schools.first }

    it "enables the feature flag for the school" do
      expect(FeatureFlag.active?(:induction_tutor_manage_participants, for: school)).to be false

      InviteSchools.new.invite_to_beta([school.urn])
      expect(FeatureFlag.active?(:induction_tutor_manage_participants, for: school)).to be true
    end

    it "emails the induction coordinator" do
      InviteSchools.new.invite_to_beta([school.urn])
      expect(SchoolMailer).to delay_email_delivery_of(:beta_invite_email)
                                .with(hash_including(
                                        recipient: induction_coordinator.email,
                                        name: induction_coordinator.full_name,
                                        school_name: school.name,
                                      ))
    end

    it "does not email the induction coordinator when the school has already been added" do
      FeatureFlag.activate(:induction_tutor_manage_participants, for: school)

      InviteSchools.new.invite_to_beta([school.urn])
      expect(SchoolMailer).not_to delay_email_delivery_of(:beta_invite_email)
    end

    it "does not enable the feature flag when there is no induction coordinator" do
      school = create(:school)
      InviteSchools.new.invite_to_beta([school.urn])
      expect(FeatureFlag.active?(:induction_tutor_manage_participants, for: school)).to be false
    end
  end
end
