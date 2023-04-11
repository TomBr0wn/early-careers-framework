# frozen_string_literal: true

module Schools
  module AddParticipants
    class WhoToAddWizard < BaseWizard
      def self.steps
        %i[
          participant_type
          yourself
          what_we_need
          name
          trn
          cannot_add_mentor_without_trn
          cannot_add_ect_because_already_a_mentor
          cannot_add_mentor_because_already_an_ect
          date_of_birth
          known_by_another_name
          different_name
          cannot_find_their_details
          nino
          still_cannot_find_their_details
          confirm_transfer
          confirm_mentor_transfer
          need_training_setup
          cannot_add
          cannot_add_mismatch
          cannot_add_mentor_at_multiple_schools
          cannot_add_already_enrolled_at_school
        ]
      end

      def save!
        save_progress!
      end

      # has this school got a cohort set up for training that matches the incoming transfer
      def need_training_setup?
        transfer_cohort = school.school_cohorts.find_by(cohort: existing_participant_cohort)
        transfer_cohort.blank? || !transfer_cohort.full_induction_programme?
      end

      # path to the most appropriate start point to set up training for the transfer
      def need_training_path
        if existing_participant_cohort == Cohort.active_registration_cohort
          expect_any_ects_schools_setup_school_cohort_path(school_id: school.slug, cohort_id: existing_participant_cohort)
        else
          schools_choose_programme_path(school_id: school.slug, cohort_id: existing_participant_cohort)
        end
      end

      def next_step_path
        if changing_answer?
          if form.revisit_next_step?
            change_path_for(step: form.next_step)
          elsif dqt_record(force_recheck: true).present?
            next_journey_path
          else
            show_path_for(step: :cannot_find_their_details)
          end
        elsif form.journey_complete?
          next_journey_path
        else
          show_path_for(step: form.next_step)
        end
      end

      def next_journey_path
        if transfer?
          start_schools_transfer_participants_path(school_id: school.slug)
        elsif sit_mentor?
          sit_start_schools_add_participants_path(school_id: school.slug)
        else
          start_schools_add_participants_path(school_id: school.slug)
        end
      end

      def already_enrolled_at_school?
        existing_induction_record.school == school
      end

      def show_path_for(step:)
        show_schools_who_to_add_participants_path(school_id: school.slug,
                                                  step: step.to_s.dasherize)
      end

      def change_path_for(step:)
        show_change_schools_who_to_add_participants_path(school_id: school.slug,
                                                         step:)
      end

      def reset_known_by_another_name_response
        data_store.set(:known_by_another_name, nil)
      end

      def dqt_record_has_different_name?
        return false unless check_for_dqt_record?

        record = dqt_record_check
        record.present? && record.dqt_record.present? && !record.name_matches && record.total_matched >= 2
      end

      def participant_exists?
        # NOTE: this doesn't differentiate being at this school from being at another school
        check_for_dqt_record? && dqt_record.present? && existing_participant_profile.present?
      end

      def existing_participant_is_a_different_type?
        participant_exists? && existing_participant_profile.participant_type != participant_type.to_sym
      end
    end
  end
end
