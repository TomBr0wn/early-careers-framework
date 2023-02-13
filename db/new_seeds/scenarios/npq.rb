# frozen_string_literal: true

module NewSeeds
  module Scenarios
    class NPQ
      attr_reader :user, :application, :participant_identity, :participant_profile, :npq_lead_provider, :npq_course

      def initialize(user: nil, lead_provider: nil, npq_course: nil)
        @supplied_user = user
        @supplied_lead_provider = lead_provider
        @supplied_npq_course = npq_course
      end

      def build
        @user = @supplied_user || FactoryBot.create(:seed_user, :valid)
        @npq_lead_provider = @supplied_lead_provider || FactoryBot.create(:seed_npq_lead_provider, :valid)
        @npq_course = @supplied_npq_course || FactoryBot.create(:seed_npq_course, :valid)

        @participant_identity = user&.participant_identities&.sample ||
          FactoryBot.create(:seed_participant_identity, user:)

        @application = FactoryBot.create(
          :seed_npq_application,
          :valid,
          *application_scopes,
          participant_identity:,
          npq_lead_provider:,
          npq_course:,
        )

        self
      end

      def accept_application
        raise(StandardError, "no npq application, call #build first") if application.blank?

        @participant_profile = FactoryBot.create(
          :seed_npq_participant_profile,
          user:,
          participant_identity:,
          npq_application: application,
          npq_course: application.npq_course,
          # it turns out that we don't find the NPQ application via the participant identity but
          # instead by the `has_one` on participant profile. The id of the NPQ application needs
          # to match the corresponding participant profile's id.
          id: application.id,
        )

        application.update!(lead_provider_approval_status: "accepted")

        self
      end

      def reject_application
        application.update!(lead_provider_approval_status: "rejected")
      end

      def add_declaration
        raise(StandardError, "no participant_profile, call #accept_application first") if participant_profile.blank?

        FactoryBot.create(
          :seed_npq_participant_declaration,
          user:,
          participant_profile:,
          course_identifier: npq_course.identifier,
          cpd_lead_provider: npq_lead_provider.cpd_lead_provider,
        )

        self
      end
    end
  end
end
