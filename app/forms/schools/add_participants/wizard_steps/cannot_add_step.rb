# frozen_string_literal: true

module Schools
  module AddParticipants
    module WizardSteps
      class CannotAddStep < ::WizardStep
        def next_step
          :none
        end

        def previous_step
          :none
        end
      end
    end
  end
end
