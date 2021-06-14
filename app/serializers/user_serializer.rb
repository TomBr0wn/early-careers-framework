# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  USER_TYPES = {
    early_career_teacher: "early_career_teacher",
    mentor: "mentor",
    other: "other",
  }.freeze

  CIP_TYPES = {
    ambition: "ambition",
    edt: "edt",
    teach_first: "teach_first",
    ucl: "ucl",
    none: "none",
  }.freeze

  PROGRAMME_TYPES = {
    core_induction_programme: "core_induction_programme",
    full_induction_programme: "full_induction_programme",
    not_yet_known: "not_yet_known",
  }.freeze

  set_id :id
  attributes :email, :full_name

  attributes :user_type do |user|
    if user.early_career_teacher?
      USER_TYPES[:early_career_teacher]
    elsif user.mentor?
      USER_TYPES[:mentor]
    else
      USER_TYPES[:other]
    end
  end

  attributes :core_induction_programme do |user|
    case user.core_induction_programme&.name
    when "Ambition Institute"
      CIP_TYPES[:ambition]
    when "Education Development Trust"
      CIP_TYPES[:edt]
    when "Teach First"
      CIP_TYPES[:teach_first]
    when "UCL Institute of Education"
      CIP_TYPES[:ucl]
    else
      CIP_TYPES[:none]
    end
  end

  attributes :induction_programme_choice do |user|
    if user.participant?
      school_cohort = SchoolCohort.find_by(school: user.school)
      case school_cohort.induction_programme_choice
      when "full_induction_programme"
        PROGRAMME_TYPES[:full_induction_programme]
      when "core_induction_programme"
        PROGRAMME_TYPES[:core_induction_programme]
      when "not_yet_known"
        PROGRAMME_TYPES[:not_yet_known]
      end
    end
  end
end
