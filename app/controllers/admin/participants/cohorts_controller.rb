# frozen_string_literal: true

module Admin::Participants
  class CohortsController < Admin::BaseController
    include RetrieveProfile
    include FindInductionRecords

    def show
      @relevant_induction_record = relevant_induction_record

      add_breadcrumb(
        school.name,
        admin_school_participants_path(school),
      )
    end

  private

    def school
      @school ||= @participant_profile.school
    end
  end
end
