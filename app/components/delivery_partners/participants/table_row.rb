# frozen_string_literal: true

module DeliveryPartners
  module Participants
    class TableRow < BaseComponent
      with_collection_parameter :participant_profile

      delegate :user,
               :teacher_profile,
               :cohort,
               :role,
               to: :participant_profile

      delegate :full_name,
               to: :user

      delegate :training_status,
               :school,
               to: :induction_record,
               allow_nil: true

      def initialize(participant_profile:, delivery_partner:)
        @participant_profile = participant_profile
        @delivery_partner = delivery_partner
      end

      def lead_provider_name
        induction_record&.induction_programme&.partnership&.lead_provider&.name
      end

      def email
        induction_record&.preferred_identity&.email || user.email
      end

    private

      attr_reader :participant_profile, :delivery_partner

      def induction_record
        @induction_record ||= participant_profile.relevant_induction_record_for(delivery_partner:)
      end
    end
  end
end
