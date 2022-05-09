# frozen_string_literal: true

module Mentors
  class Create < BaseService
    include SchoolCohortDelegator

    def call
      mentor_profile = nil
      ActiveRecord::Base.transaction do
        # NOTE: This will not update the full_name if the user has an active participant profile,
        # the scenario I am working on is enabling a NPQ user to be added as a mentor
        # Not matching on full_name means this works more smoothly for the end user
        # and they don't get "email already in use" errors if they spell the name differently
        user = User.find_or_create_by!(email: email) do |mentor|
          mentor.full_name = full_name
        end
        user.update!(full_name: full_name) unless user.teacher_profile&.participant_profiles&.active_record&.any?

        teacher_profile = TeacherProfile.find_or_create_by!(user: user) do |profile|
          profile.school = school_cohort.school
        end

        mentor_profile = ParticipantProfile::Mentor.create!({
          teacher_profile: teacher_profile,
          schedule: Finance::Schedule::ECF.default_for(cohort: school_cohort.cohort),
          participant_identity: Identity::Create.call(user: user),
        }.merge(mentor_attributes))

        ParticipantProfileState.create!(participant_profile: mentor_profile)

        if school_cohort.default_induction_programme.present?
          Induction::Enrol.call(participant_profile: mentor_profile,
                                induction_programme: school_cohort.default_induction_programme)
        end
      end

      ParticipantMailer.participant_added(participant_profile: mentor_profile).deliver_later
      mentor_profile.update_column(:request_for_details_sent_at, Time.zone.now)
      ParticipantDetailsReminderJob.schedule(mentor_profile)

      mentor_profile
    end

  private

    attr_reader :full_name, :email, :start_term, :school_cohort

    def initialize(full_name:, email:, school_cohort:, start_term: nil, **)
      @full_name = full_name
      @email = email
      @start_term = start_term || school_cohort.cohort.start_term_options.first
      @school_cohort = school_cohort
    end

    def mentor_attributes
      {
        start_term: start_term,
        school_cohort_id: school_cohort.id,
        sparsity_uplift: sparsity_uplift?(start_year),
        pupil_premium_uplift: pupil_premium_uplift?(start_year),
      }
    end
  end
end
