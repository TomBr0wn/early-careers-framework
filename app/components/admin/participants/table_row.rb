# frozen_string_literal: true

module Admin
  module Participants
    class TableRow < BaseComponent
      with_collection_parameter :profile

      def initialize(profile:)
        @profile = profile
      end

    private

      attr_reader :profile
      delegate :school, to: :profile

      def validation_status
        return { text: "Not ready", colour: "grey" } unless profile.npq?

        { text: "Pending", colour: "yellow" }
      end
    end
  end
end
