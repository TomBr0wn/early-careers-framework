# frozen_string_literal: true

module Dashboard
  class Participants
    class Filter
      include ActiveModel::Model

      attr_accessor :dashboard_participants, :filtered_by, :sorted_by

      FILTER_OPTIONS = %w[
        currently_training
        completed_induction
        no_longer_training
      ].freeze

      SORT_OPTIONS = %w[
        mentor
        induction_start_date
      ].freeze

      def initialize(*)
        super
        self.filtered_by = FILTER_OPTIONS.first unless FILTER_OPTIONS.include?(filtered_by)
        self.sorted_by = SORT_OPTIONS.first unless SORT_OPTIONS.include?(sorted_by)
      end

      def filter_options
        @filter_options ||= FILTER_OPTIONS.map do |id|
          Dashboard::Participants::Filter::Option.new(id:, dashboard_participants:)
        end
      end

      def sorted_by?(sort_option)
        sorted_by == sort_option.to_s
      end
    end
  end
end
