# frozen_string_literal: true

module Schools
  module AddParticipants
    module WizardSteps
      class ChooseMentorStep < ::WizardStep
        attr_accessor :mentor_id

        validates :mentor_id, presence: true, inclusion: { in: ->(form) { form.wizard.mentor_options.map(&:id) + %w[later] } }

        def self.permitted_params
          %i[
            mentor_id
          ]
        end

        def next_step
          if wizard.needs_to_confirm_appropriate_body?
            :confirm_appropriate_body
          elsif wizard.needs_to_confirm_programme?
            :continue_current_programme
          else
            :check_answers
          end
        end

        def previous_step
          :what_we_need
        end
      end
    end
  end
end
