# frozen_string_literal: true

module Admin::Participants
  class SchoolController < Admin::BaseController
    include RetrieveProfile
    include FindInductionRecords

    def show
      @latest_induction_record = latest_induction_record
      @school_cohort = @latest_induction_record&.school_cohort
      @lead_provider = @school_cohort&.lead_provider
      @school = @school_cohort&.school
    end
  end
end
