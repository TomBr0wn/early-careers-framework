# frozen_string_literal: true

require "pagy"

module ApplicationHelper
  include Pagy::Frontend

  def profile_dashboard_path(user)
    if user.admin?
      admin_schools_path
    elsif user.finance?
      finance_landing_page_path
    elsif user.induction_coordinator_and_mentor?
      induction_coordinator_mentor_path(user)
    elsif user.induction_coordinator?
      induction_coordinator_dashboard_path(user)
    elsif user.teacher?
      participant_start_path(user)
    else
      dashboard_path
    end
  end

  def data_layer
    @data_layer ||= build_data_layer
  end

  def build_data_layer
    analytics_data = AnalyticsDataLayer.new
    analytics_data.add_user_info(current_user) if current_user
    analytics_data.add_school_info(assigns["school"]) if assigns["school"]
    analytics_data
  end

  def induction_coordinator_dashboard_path(user)
    return schools_dashboard_index_path if user.schools.count > 1

    school = user.induction_coordinator_profile.schools.first
    return schools_choose_programme_path(school_id: school.slug, cohort_id: Cohort.current.start_year) unless school.chosen_programme?(Cohort.current)

    schools_dashboard_path(school_id: school.slug)
  end

  def participant_start_path(user)
    return participants_no_access_path unless post_2020_ecf_participant?(user)

    participants_validation_path
  end

  def service_name
    if request.path.include? "year-2020"
      "Get support materials for NQTs"
    else
      "Manage training for early career teachers"
    end
  end

  def text_otherwise_link_to(text, url, condition_for_text)
    if condition_for_text
      text
    else
      govuk_link_to text, url
    end
  end

  def wide_container_view?
    params[:controller].start_with?("finance")
  end

private

  def post_2020_ecf_participant?(user)
    user.teacher_profile.current_ecf_profile.present?
  end

  def induction_coordinator_mentor_path(user)
    profile = user.participant_profiles.active_record.mentors.first
    return participants_validation_path unless profile&.completed_validation_wizard?

    induction_coordinator_dashboard_path(user)
  end
end
