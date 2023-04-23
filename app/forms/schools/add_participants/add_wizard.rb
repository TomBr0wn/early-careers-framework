# frozen_string_literal: true

module Schools
  module AddParticipants
    class AddWizard < BaseWizard
      def self.steps
        %i[
          email
          email_already_taken
          start_date
          start_term
          cannot_add_registration_not_yet_open
          choose_mentor
          confirm_appropriate_body
          check_answers
          complete
        ]
      end

      def save!
        save_progress!

        if form.journey_complete?
          set_participant_profile(add_participant!)
          complete!
        end
      end

      def next_step_path
        if changing_answer?
          if form.revisit_next_step?
            change_path_for(step: form.next_step)
          elsif email.present?
            show_path_for(step: :check_answers)
          else
            show_path_for(step: :email)
          end
        else
          show_path_for(step: form.next_step)
        end
      end

      def previous_step_path
        # back_step = form.previous_step
        back_step = last_visited_step
        return abort_path if back_step.nil?

        if changing_answer? || %i[name different_name].exclude?(back_step)
          super
        elsif FeatureFlag.active?(:cohortless_dashboard)
          schools_who_to_add_show_path(**path_options(step: back_step)) # previous wizard
        else
          show_schools_who_to_add_participants_path(**path_options(step: back_step)) # previous wizard
        end
      end

      def show_path_for(step:)
        if FeatureFlag.active? :cohortless_dashboard
          schools_add_show_path(**path_options(step:))
        else
          show_schools_add_participants_path(**path_options(step:))
        end
      end

      def change_path_for(step:)
        if FeatureFlag.active? :cohortless_dashboard
          schools_add_show_change_path(**path_options(step:))
        else
          show_change_schools_add_participants_path(**path_options(step:))
        end
      end

      def participant_exists?
        # NOTE: this doesn't differentiate being at this school from being at another school
        check_for_dqt_record? && dqt_validation && existing_participant_profile.present?
      end

      def check_for_dqt_record?
        full_name.present? && trn.present? && date_of_birth.present?
      end

      ## ECT journey
      def needs_to_choose_a_mentor?
        ect_participant? && mentor_id.blank? && mentor_options.any?
      end

      def needs_to_confirm_start_term?
        # are we in the period for registrations for the next cohort prior to
        # the next academic year start?
        Cohort.within_next_registration_period?
      end

      # check answers helpers
      def show_default_induction_programme_details?
        !!(school_cohort&.default_induction_programme && school_cohort.default_induction_programme&.partnership&.active?)
      end

      # only relevant when we are in the registration period before the next cohort starts
      # and the participant doesn't have an induction start date registered with DQT
      def show_start_term?
        induction_start_date.blank? && start_term.present?
      end

      def start_term_description
        "#{start_term.capitalize} #{start_term == 'spring' ? Time.zone.now.year + 1 : Time.zone.now.year}"
      end

    private

      def add_participant!
        # Finish enroll process and send notification emails
        profile = nil
        ActiveRecord::Base.transaction do
          profile = if ect_participant?
                      EarlyCareerTeachers::Create.call(**participant_create_args)
                    else
                      Mentors::Create.call(**participant_create_args)
                    end

          store_validation_result!(profile)
        end

        send_added_and_validated_email(profile) if profile && profile.ecf_participant_validation_data.present? && !sit_mentor?

        profile
      end

      def store_validation_result!(profile)
        ::Participants::ParticipantValidationForm.call(
          profile,
          data: {
            trn: formatted_trn,
            nino: formatted_nino,
            date_of_birth:,
            full_name:,
          },
        )
      end

      def send_added_and_validated_email(profile)
        ParticipantMailer.sit_has_added_and_validated_participant(participant_profile: profile, school_name: school.name).deliver_later
      end

      def participant_create_args
        {
          full_name:,
          email:,
          school_cohort:,
          mentor_profile_id: mentor_profile&.id,
          sit_validation: true,
          appropriate_body_id:,
          induction_start_date:,
        }
      end
    end
  end
end
