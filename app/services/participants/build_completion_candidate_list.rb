# frozen_string_literal: true

# This service builds a list of candidates to check for an induction completion date
# The list will be processed by the SetParticipantCompletionDateJob
# This could be improved later to more intelligently select which records to include
# as at the moment it's just including all 2021 and 2022 ECTs
module Participants
  class BuildCompletionCandidateList < BaseService
    def call
      ActiveRecord::Base.transaction do
        clean_candidate_list
        build_candidate_list
      end
      CompletionCandidate.count
    end

  private

    def clean_candidate_list
      CompletionCandidate.delete_all
    end

    def build_candidate_list
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          INSERT INTO completion_candidates (participant_profile_id)
          SELECT pp.id
          FROM participant_profiles pp
          JOIN teacher_profiles tp ON tp.id = pp.teacher_profile_id
          JOIN schedules s ON s.id = pp.schedule_id
          JOIN cohorts c ON c.id = s.cohort_id
          WHERE pp.type = 'ParticipantProfile::ECT'
          AND c.start_year IN (2020,2021,2022)
          AND pp.induction_start_date IS NOT NULL
          AND pp.induction_completion_date IS NULL
          AND pp.created_at < '#{registration_start_date}'
          AND tp.trn IS NOT NULL;
        SQL
      )
    end

    def registration_start_date
      Cohort.find_by(start_year: 2023).registration_start_date.to_date.to_s
    end
  end
end
