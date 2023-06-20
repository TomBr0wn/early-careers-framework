# frozen_string_literal: true

module Api
  module V3
    class ParticipantDeclarationsQuery
      attr_reader :cpd_lead_provider, :params

      def initialize(cpd_lead_provider:, params:)
        @cpd_lead_provider = cpd_lead_provider
        @params = params
      end

      def participant_declarations_for_pagination
        scope = ActiveRecordUnion.new(
          declarations_scope,
          previous_declarations_scope,
        ).call

        if participant_ids.present?
          scope = scope.where(user_id: participant_ids)
        end

        if updated_since.present?
          scope = scope.where(updated_at: updated_since..)
        end

        if delivery_partner_ids.present?
          scope = scope.where(delivery_partner_id: delivery_partner_ids)
        end

        scope
          .select(:id, :created_at)
          .order(:created_at)
          .distinct
      end

      def participant_declarations_from(paginated_join)
        scope = ParticipantDeclaration
            .includes(
              :statement_line_items,
              :declaration_states,
              :participant_profile,
              :cpd_lead_provider,
            )
            .joins("INNER JOIN (#{paginated_join.to_sql}) as tmp on tmp.id = participant_declarations.id")
            .order(:created_at)
            .distinct

        preloader = ActiveRecord::Associations::Preloader.new
        preloader.preload(scope.select { |p| p.type == "ParticipantDeclaration::NPQ" }, :outcomes)
        preloader.preload(scope.select { |p| p.type == "ParticipantDeclaration::NPQ" }, participant_profile: :npq_application)

        scope
      end

    private

      delegate :lead_provider, to: :cpd_lead_provider

      def declarations_scope
        scope = with_joins(ParticipantDeclaration.for_lead_provider(cpd_lead_provider))

        if cohort_start_years.present?
          scope = scope.where(participant_profile: { induction_records: { cohorts: { start_year: cohort_start_years } } })
        end

        scope
      end

      def previous_declarations_scope
        scope = with_joins(ParticipantDeclaration)
          .where(participant_profile: { induction_records: { induction_programme: { partnerships: { lead_provider: } } } })
          .where(participant_profile: { induction_records: { induction_status: "active" } }) # only want induction records that are the winning latest ones
          .where(state: %w[submitted eligible payable paid])

        if cohort_start_years.present?
          scope = scope.where(participant_profile: { induction_records: { cohorts: { start_year: cohort_start_years } } })
        end

        scope
      end

      def filter
        params[:filter] ||= {}
      end

      def participant_ids
        filter[:participant_id]&.split(",")
      end

      def delivery_partner_ids
        filter[:delivery_partner_id]&.split(",")
      end

      def updated_since
        return if filter[:updated_since].blank?

        Time.iso8601(filter[:updated_since])
      rescue ArgumentError
        begin
          Time.iso8601(URI.decode_www_form_component(filter[:updated_since]))
        rescue ArgumentError
          raise Api::Errors::InvalidDatetimeError, I18n.t(:invalid_updated_since_filter)
        end
      end

      def cohort_start_years
        filter[:cohort]&.split(",")
      end

      def with_joins(scope)
        scope.left_outer_joins(
          participant_profile: [
            induction_records: [
              :cohort,
              { induction_programme: { partnership: [:lead_provider] } },
            ],
          ],
        )
      end
    end
  end
end
