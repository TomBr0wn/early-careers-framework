# frozen_string_literal: true

module Schools
  module AddParticipants
    module WizardSteps
      class DifferentNameStep < ::WizardStep
        attr_accessor :full_name

        validates :full_name, presence: true

        def self.permitted_params
          %i[
            full_name
          ]
        end

        def next_step
          if wizard.participant_exists?
            if wizard.dqt_record_has_different_name? && wizard.participant_has_different_name?
              :known_by_another_name
            elsif wizard.existing_participant_is_a_different_type?
              if wizard.ect_participant?
                # trying to add an ECT who is already a mentor
                :cannot_add_ect_because_already_a_mentor
              else
                # trying to add a mentor who is already an ECT
                :cannot_add_mentor_because_already_an_ect
              end
            elsif wizard.already_enrolled_at_school?
              :cannot_add_already_enrolled_at_school
            elsif wizard.ect_participant?
              :confirm_transfer
            else
              :confirm_mentor_transfer
            end
          elsif wizard.dqt_record_has_different_name?
            :known_by_another_name
          else
            :none
          end
        end

        # def previous_step
        #   :known_by_another_name
        # end

        def journey_complete?
          next_step == :none
        end
      end
    end
  end
end
