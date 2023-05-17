# frozen_string_literal: true

module StatusTags
  class AppropriateBodyParticipantStatusTag < BaseComponent
    def initialize(participant_profile:, induction_record: nil)
      @participant_profile = participant_profile
      @induction_record = induction_record
    end

    def label
      t :label, scope: translation_scope
    end

    def id
      t :id, scope: translation_scope
    end

    def description
      Array.wrap(t(:description, scope: translation_scope, contact_us: render(MailToSupportComponent.new("contact us")))).map(&:html_safe)
    rescue I18n::MissingTranslationData
      []
    end

    def colour
      t :colour, scope: translation_scope
    end

  private

    attr_reader :participant_profile, :induction_record

    def translation_scope
      @translation_scope ||= "status_tags.appropriate_body_participant_status.#{record_state}"
    end

    def record_state
      @record_state ||= DetermineTrainingRecordState.call(participant_profile:, induction_record:)&.record_state || :no_longer_involved
    end
  end
end
