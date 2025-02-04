# frozen_string_literal: true

require "csv"

module Api
  module V2
    class NPQApplicationCsvSerializer
      attr_reader :scope

      def initialize(scope)
        @scope = scope
      end

      def call
        CSV.generate do |csv|
          csv << csv_headers

          scope.each do |record|
            csv << to_row(record)
          end
        end
      end

    private

      def csv_headers
        %w[
          id
          participant_id
          full_name
          email
          email_validated
          teacher_reference_number
          teacher_reference_number_validated
          school_urn
          school_ukprn
          private_childcare_provider_urn
          headteacher_status
          eligible_for_funding
          funding_choice
          course_identifier
          status
          works_in_school
          employer_name
          employment_role
          created_at
          updated_at
          cohort
          ineligible_for_funding_reason
          targeted_delivery_funding_eligibility
          itt_provider
          lead_mentor
        ]
      end

      def to_row(record)
        [
          record.id,
          record.participant_identity.user_id,
          record.participant_identity.user.full_name,
          record.participant_identity.email,
          true,
          record.teacher_reference_number,
          record.teacher_reference_number_verified,
          record.school_urn,
          record.school_ukprn,
          record.private_childcare_provider_urn,
          record.headteacher_status,
          record.eligible_for_dfe_funding,
          record.funding_choice,
          record.npq_course.identifier,
          record.lead_provider_approval_status,
          record.works_in_school,
          record.employer_name,
          record.employment_role,
          record.created_at.rfc3339,
          updated_at(record),
          record.cohort.start_year,
          record.ineligible_for_funding_reason,
          record.targeted_delivery_funding_eligibility,
          record.itt_provider,
          record.lead_mentor,
        ]
      end

      def updated_at(record)
        [
          record.profile&.updated_at,
          record.user.updated_at,
          record.participant_identity.updated_at,
          record.updated_at,
        ].compact.max.rfc3339
      end
    end
  end
end
