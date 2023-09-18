# frozen_string_literal: true

module Mentors
  class Create < BaseService
    include SchoolCohortDelegator
    ParticipantProfileExistsError = Class.new(RuntimeError)

    def call
      mentor_profile = nil
      ActiveRecord::Base.transaction do
        user.update!(full_name:) unless user.teacher_profile&.participant_profiles&.active_record&.any?

        create_teacher_profile

        mentor_profile = find_or_create_participant_profile

        ParticipantProfileState.create!(participant_profile: mentor_profile,
                                        cpd_lead_provider: school_cohort&.default_induction_programme&.lead_provider&.cpd_lead_provider)

        if school_cohort.default_induction_programme.present?
          Induction::Enrol.call(participant_profile: mentor_profile,
                                induction_programme: school_cohort.default_induction_programme,
                                start_date:)
        end

        Mentors::AddToSchool.call(school: school_cohort.school, mentor_profile:)
      end

      mentor_profile
    end

  private

    attr_reader :full_name, :email, :school_cohort, :start_date

    def initialize(full_name:, email:, school_cohort:, start_date: nil, **)
      @full_name = full_name
      @email = email
      @start_date = start_date
      @school_cohort = school_cohort
    end

    def mentor_attributes
      {
        school_cohort_id: school_cohort.id,
        sparsity_uplift: sparsity_uplift?(start_year),
        pupil_premium_uplift: pupil_premium_uplift?(start_year),
      }
    end

    def user
      # NOTE: This will not update the full_name if the user has an active participant profile,
      # the scenario I am working on is enabling a NPQ user to be added as a mentor
      # Not matching on full_name means this works more smoothly for the end user
      # and they don't get "email already in use" errors if they spell the name differently
      @user ||= find_or_create_user!
    end

    def mentor_update_attributes
      {
        teacher_profile:,
        status: :active,
        schedule: Finance::Schedule::ECF.default_for(cohort: school_cohort.cohort),
      }.merge(mentor_attributes)
    end

    def mentor_create_attributes
      mentor_update_attributes.merge(participant_identity: Identity::Create.call(user:, email:))
    end

    def find_or_create_participant_profile
      if existing_participant_profile.present?
        existing_participant_profile.update!(mentor_update_attributes)
        existing_participant_profile
      else
        ParticipantProfile::Mentor.create!(mentor_create_attributes)
      end
    end

    def existing_participant_profile
      via_teacher_profile = teacher_profile.participant_profiles.mentors.first
      return via_teacher_profile if via_teacher_profile.present?

      participant_identity = ParticipantIdentityResolver.call(
        participant_id: user.id,
        course_identifier: "ecf-mentor",
        cpd_lead_provider: nil,
      )
      ParticipantProfileResolver.call(
        participant_identity:,
        course_identifier: "ecf-mentor",
        cpd_lead_provider: nil,
      )
    end

    def find_or_create_user!
      Identity.find_user_by(email:) || User.create!(email:, full_name:)
    end

    def teacher_profile
      @teacher_profile ||= TeacherProfile.find_or_create_by!(user:).tap do |teacher_profile|
        teacher_profile.update!(school: school_cohort.school)
      end
    end
    alias_method :create_teacher_profile, :teacher_profile
  end
end
