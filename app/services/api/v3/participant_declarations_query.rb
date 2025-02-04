# frozen_string_literal: true

module Api
  module V3
    class ParticipantDeclarationsQuery
      include Api::Concerns::FilterCohorts
      include Api::Concerns::FilterUpdatedSince

      attr_reader :cpd_lead_provider, :params

      def initialize(cpd_lead_provider:, params:)
        @cpd_lead_provider = cpd_lead_provider
        @params = params
      end

      def participant_declarations_for_pagination
        filterable_attributes = %i[id created_at user_id updated_at delivery_partner_id]
        scope = ParticipantDeclaration.union(
          declarations_scope.select(*filterable_attributes),
          ecf_previous_declarations_scope.select(*filterable_attributes),
        )

        if participant_ids.present?
          scope = scope.where(user_id: participant_ids)
        end

        if updated_since_filter.present?
          scope = scope.where(updated_at: updated_since..)
        end

        if delivery_partner_ids.present?
          scope = scope.where(delivery_partner_id: delivery_partner_ids)
        end

        scope
         .select(:id, :created_at)
         .order(:created_at)
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

        ActiveRecord::Associations::Preloader.new(
          records: scope.select { |p| p.type == "ParticipantDeclaration::NPQ" },
          associations: [:outcomes, { participant_profile: :npq_application }],
        ).call

        scope
      end

      def participant_declaration(id)
        ParticipantDeclaration.union(
          declarations_scope,
          ecf_previous_declarations_scope,
        ).find(id)
      end

    private

      def lead_provider
        cpd_lead_provider.lead_provider if cpd_lead_provider.respond_to?(:lead_provider)
      end

      def npq_lead_provider
        cpd_lead_provider.npq_lead_provider if cpd_lead_provider.respond_to?(:npq_lead_provider)
      end

      def declarations_scope
        scope = ParticipantDeclaration.for_lead_provider(cpd_lead_provider)

        if cohort_years.present?
          scope = ecf_cohort_for(scope).or(npq_cohort_for(scope))
        end

        scope
      end

      def ecf_cohort_for(scope)
        return ParticipantDeclaration.none if lead_provider.blank?

        with_joins(scope).where(participant_profile: { induction_records: { cohorts: { start_year: cohort_years } } })
      end

      def npq_cohort_for(scope)
        return ParticipantDeclaration.none if npq_lead_provider.blank?

        with_joins(scope).where(participant_profile: { type: "ParticipantProfile::NPQ", schedule: { cohorts: { start_year: cohort_years } } })
      end

      def ecf_previous_declarations_scope
        scope = with_joins(ParticipantDeclaration)
          .where(participant_profile: { induction_records: { induction_programme: { partnerships: { lead_provider_id: lead_provider&.id } } } })
          .where(participant_profile: { induction_records: { induction_status: "active" } }) # only want induction records that are the winning latest ones
          .where(state: %w[submitted eligible payable paid])

        if cohort_years.present? && lead_provider.present?
          scope = scope.where(participant_profile: { induction_records: { cohorts: { start_year: cohort_years } } })
        end

        scope
      end

      def participant_ids
        filter[:participant_id]&.split(",")
      end

      def delivery_partner_ids
        filter[:delivery_partner_id]&.split(",")
      end

      def with_joins(scope)
        scope.left_outer_joins(
          participant_profile: [
            [schedule: :cohort],
            { induction_records: [
              :cohort,
              { induction_programme: :partnership },
            ] },
          ],
        )
      end
    end
  end
end
