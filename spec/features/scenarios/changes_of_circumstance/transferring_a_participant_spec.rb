# frozen_string_literal: true

require "rails_helper"
require_relative "./changes_of_circumstance_scenario"

def given_context(scenario)
  str = "[#{scenario.number}]"
  str += " Given a #{scenario.participant_type}"
  str += " is to transfer from #{scenario.original_programme} to #{scenario.new_programme}"
  str + " using #{scenario.transfer == :same_provider ? 'the Same Provider' : 'a Different Provider'}"
end

def when_context(scenario)
  str = "When they are transferred by the new SIT"
  str += " before any declarations are made" if (scenario.new_declarations + scenario.prior_declarations).empty?
  str += " after the declarations #{scenario.prior_declarations} have been made" if scenario.prior_declarations.any?
  str += " and the new declarations #{scenario.new_declarations} are then made" if scenario.new_declarations.any?
  str
end

RSpec.feature "Transfer a participant", type: :feature, end_to_end_scenario: true do
  include Steps::ChangesOfCircumstanceSteps

  let(:cohort) { create :cohort, :current }
  let(:privacy_policy)  { create :privacy_policy }

  let(:tokens) { {} }

  before do
    create(:ecf_schedule)
  end

  fixture_data_path = File.join(File.dirname(__FILE__), "./transferring_a_participant_fixtures.csv")
  CSV.parse(File.read(fixture_data_path), headers: true).each_with_index do |fixture_data, index|
    scenario = ChangesOfCircumstanceScenario.new index + 2, fixture_data

    # NOTE: uncomment to specify a specific test to run
    # next unless index + 2 == 8

    context given_context(scenario) do
      let(:new_lead_provider_name) { scenario.transfer == :same_provider ? "Original Lead Provider" : "New Lead Provider" }

      before do
        given_lead_providers_contracted_to_deliver_ecf "Original Lead Provider"
        given_lead_providers_contracted_to_deliver_ecf "New Lead Provider"
        given_lead_providers_contracted_to_deliver_ecf "Another Lead Provider"

        and_sit_at_pupil_premium_school_reported_programme "Original SIT", scenario.original_programme
        if scenario.original_programme == "FIP"
          and_lead_provider_reported_partnership "Original Lead Provider", "Original SIT"
        end

        and_sit_at_pupil_premium_school_reported_programme "New SIT", scenario.new_programme
        if scenario.new_programme == "FIP"
          and_lead_provider_reported_partnership new_lead_provider_name, "New SIT"
        end

        and_feature_flag_is_active :eligibility_notifications

        and_sit_reported_participant "Original SIT", "the Participant", scenario.participant_type
        and_participant_has_completed_registration "the Participant"
      end

      context when_context(scenario) do
        before do
          scenario.prior_declarations.each do |declaration_type|
            and_lead_provider_has_made_training_declaration "Original Lead Provider", "the Participant", declaration_type
          end

          when_school_takes_on_the_participant "New SIT", "the Participant"

          scenario.new_declarations.each do |declaration_type|
            and_lead_provider_has_made_training_declaration new_lead_provider_name, "the Participant", declaration_type
          end

          and_eligible_training_declarations_are_made_payable

          and_lead_provider_statements_have_been_created "Original Lead Provider"
          and_lead_provider_statements_have_been_created "New Lead Provider"
          and_lead_provider_statements_have_been_created "Another Lead Provider"
        end

        context "Then the Original SIT" do
          subject(:original_sit) { "Original SIT" }

          it { should_not be_able_to_find_the_details_of_the_participant_in_the_school_induction_portal "the Participant" }
        end

        context "Then the New SIT" do
          subject(:new_sit) { "New SIT" }

          it { should be_able_to_find_the_details_of_the_participant_in_the_school_induction_portal "the Participant" }
          it { should be_able_to_find_the_participant_status_in_the_school_induction_portal "the Participant", scenario.new_school_status }

          # what are the onward actions available to the new school - can they do them ??
        end

        context "Then the Original Lead Provider" do
          subject(:original_lead_provider) { "Original Lead Provider" }

          case scenario.see_original_details
          when :ALL
            it { should be_able_to_retrieve_the_details_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.participant_type }
            it { should be_able_to_retrieve_the_status_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.prior_participant_status }
            it { should be_able_to_retrieve_the_training_status_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.prior_training_status }
          when :OBFUSCATED
            it "is expected to be able to retrieve the obfuscated details of the participant from the ecf participants endpoint",
               skip: "Not yet implemented" do
              # should be_able_to_retrieve_the_obfuscated_details_of_the_participant_from_the_ecf_participants_endpoint "Original Lead Provider"
            end
            it "is expected to be able to retrieve the status '#{scenario.prior_participant_status}' of the participant from the ecf participants endpoint",
               skip: "Not yet implemented" do
              # should be_able_to_retrieve_the_status_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.prior_participant_status }
            end
            it "is expected to be able to retrieve the training status '#{scenario.prior_training_status}' of the participant from the ecf participants endpoint",
               skip: "Not yet implemented" do
              # should be_able_to_retrieve_the_training_status_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.prior_training_status }
            end
          else
            it { should_not be_able_to_retrieve_the_details_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.participant_type }
          end

          if scenario.see_original_declarations.any?
            it { should be_able_to_retrieve_the_training_declarations_for_the_participant_from_the_ecf_declarations_endpoint "the Participant", scenario.see_original_declarations }
          end

          # previous lead provider can void ??
        end

        context "Then the New Lead Provider" do
          subject(:new_lead_provider) { "New Lead Provider" }

          case scenario.see_new_details
          when :ALL
            it { should be_able_to_retrieve_the_details_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.participant_type }
            it { should be_able_to_retrieve_the_status_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.new_participant_status }
            it { should be_able_to_retrieve_the_training_status_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.new_training_status }
          when :not_applicable
            # not applicable
          else
            raise "scenario.see_new_details is not a valid value"
          end

          scenario.duplicate_declarations.each do |declaration_type|
            it { should be_blocked_from_making_a_duplicate_training_declaration_for_the_participant "the Participant", declaration_type }
          end

          if scenario.see_new_declarations.any?
            if scenario.transfer != :different_provider
              it { should be_able_to_retrieve_the_training_declarations_for_the_participant_from_the_ecf_declarations_endpoint "the Participant", scenario.see_new_declarations }
            else
              it "is expected to be able to retrieve the declarations [#{scenario.see_new_declarations}] for the training of 'the Participant' from the ecf declarations endpoint",
                 skip: "Not yet implemented" do
                # should be_able_to_retrieve_the_training_declarations_for_the_participant_from_the_ecf_declarations_endpoint "the Participant", scenario.see_new_declarations }
              end
            end
          end
        end

        context "Then other Lead Providers" do
          subject(:another_lead_provider) { "Another Lead Provider" }

          it { should_not be_able_to_retrieve_the_details_of_the_participant_from_the_ecf_participants_endpoint "the Participant", scenario.participant_type }
          it { should be_able_to_retrieve_the_training_declarations_for_the_participant_from_the_ecf_declarations_endpoint "the Participant", [] }
        end

        context "Then the Support for Early Career Teachers Service", :skip do
          subject(:support_ects) { "Support for Early Career Teachers Service" }

          it { should be_able_to_retrieve_the_details_of_the_participant_from_the_ecf_users_endpoint "the Participant", scenario.new_programme, scenario.participant_type }
        end

        context "Then a Teacher CPD Finance User" do
          subject(:finance_user) { create :user, :finance }

          it { should be_able_to_find_the_school_of_the_participant_in_the_finance_portal "the Participant", "New SIT" }
          unless scenario.new_programme == "CIP"
            it { should be_able_to_find_the_lead_provider_of_the_participant_in_the_finance_portal "the Participant", new_lead_provider_name }
          end
          it { should be_able_to_find_the_status_of_the_participant_in_the_finance_portal "the Participant", scenario.new_participant_status }
          it { should be_able_to_find_the_training_status_of_the_participant_in_the_finance_portal "the Participant", scenario.new_training_status }
          it { should be_able_to_find_the_training_declarations_for_the_participant_in_the_finance_portal "the Participant", scenario.see_new_declarations }

          it { should be_able_to_see_recruitment_summary_for_lead_provider_in_payment_breakdown "Original Lead Provider", scenario.original_payment_ects, scenario.original_payment_mentors }
          it { should be_able_to_see_payment_summary_for_lead_provider_in_payment_breakdown "Original Lead Provider", scenario.original_payment_declarations }
          it { should be_able_to_see_started_declaration_payment_for_lead_provider_in_payment_breakdown "Original Lead Provider", scenario.original_payment_ects, scenario.original_payment_mentors, scenario.original_payment_declarations }
          it { should be_able_to_see_other_fees_for_the_lead_provider_in_the_finance_portal "Original Lead Provider", scenario.original_payment_ects, scenario.original_payment_mentors }

          it { should be_able_to_see_recruitment_summary_for_lead_provider_in_payment_breakdown "New Lead Provider", scenario.new_payment_ects, scenario.new_payment_mentors }
          it { should be_able_to_see_payment_summary_for_lead_provider_in_payment_breakdown "New Lead Provider", scenario.new_payment_declarations }
          it { should be_able_to_see_started_declaration_payment_for_lead_provider_in_payment_breakdown "New Lead Provider", scenario.new_payment_ects, scenario.new_payment_mentors, scenario.new_payment_declarations }
          it { should be_able_to_see_other_fees_for_the_lead_provider_in_the_finance_portal "New Lead Provider", scenario.new_payment_ects, scenario.new_payment_mentors }
        end

        context "Then a Teacher CPD Admin User" do
          subject(:admin_user) { create :user, :admin }

          it "should not find details of the Participant in the Original SIT's School page", :skip do
            sit_name = "Original SIT"
            participant_name = "the Participant"

            sign_in_as admin_user

            within "main" do
              click_on "#{sit_name}'s School"
            end

            within "main" do
              click_on "Participants"
            end

            within "main" do
              # TODO: this should fail
              click_on participant_name
              puts page.html
            end
          end

          it "should find details of the Participant in the New SIT's School page" do
            sit_name = "New SIT"
            participant_name = "the Participant"

            sign_in_as admin_user

            within "main" do
              click_on "#{sit_name}'s School"
            end

            within "main" do
              click_on "Participants"
            end

            within "main" do
              click_on participant_name

              has_text? "#{participant_name} Eligible to start"
              has_text? "Full name #{participant_name}"
              has_text? "School #{sit_name}'s School"
            end
          end
        end

        context "Then the Analytics Dashboards", :skip do
          it "should report the correct changes of circumstance" do
            participant_name = "the Participant"

            user = User.find_by(full_name: participant_name)
            raise "Could not find User for #{participant_name}" if user.nil?

            participant_profile = user.participant_profiles.first
            raise "Could not find ParticipantProfile for #{participant_name}" if participant_profile.nil?

            expect(Analytics::UpsertECFParticipantProfileJob).to have_been_enqueued.with(participant_profile: participant_profile)
          end
        end

        # TODO: what would analytics have gathered ??
      end
    end
  end
end
