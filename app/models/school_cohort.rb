# frozen_string_literal: true

class SchoolCohort < ApplicationRecord
  enum induction_programme_choice: {
    full_induction_programme: "full_induction_programme",
    core_induction_programme: "core_induction_programme",
    design_our_own: "design_our_own",
    no_early_career_teachers: "no_early_career_teachers",
    not_yet_known: "not_yet_known",
  }

  has_paper_trail

  belongs_to :cohort
  belongs_to :school
  belongs_to :core_induction_programme, optional: true

  has_many :ecf_participant_profiles, class_name: "ParticipantProfile"
  has_many :ecf_participants, through: :ecf_participant_profiles, source: :user
  has_many :active_ecf_participant_profiles, -> { ecf.active_record }, class_name: "ParticipantProfile"
  has_many :active_ecf_participants, through: :active_ecf_participant_profiles, source: :user

  has_many :mentor_profiles, -> { mentors }, class_name: "ParticipantProfile"
  has_many :mentors, through: :mentor_profiles, source: :user
  has_many :active_mentor_profiles, -> { mentors.active_record }, class_name: "ParticipantProfile"
  has_many :active_mentors, through: :active_mentor_profiles, source: :user

  scope :for_year, ->(year) { joins(:cohort).where(cohort: { start_year: year }) }

  after_commit do
    ecf_participant_profiles.touch_all
    ecf_participants.touch_all
  end

  def training_provider_status
    school.partnerships&.active&.exists?(cohort: cohort) ? "Done" : "To do"
  end

  def lead_provider
    school.lead_provider(cohort.start_year)
  end

  def delivery_partner
    school.delivery_partner_for(cohort.start_year)
  end

  def add_participants_status
    if FeatureFlag.active?(:induction_tutor_manage_participants, for: school)
      "To do"
    else
      "Cannot start yet"
    end
  end

  def choose_training_materials_status
    core_induction_programme_id ? "Done" : "To do"
  end

  def status
    if core_induction_programme?
      cip_status
    elsif full_induction_programme?
      fip_status
    elsif not_yet_known?
      "To do"
    end
  end

  def school_chose_cip?
    induction_programme_choice == "core_induction_programme"
  end

  def school_chose_fip?
    induction_programme_choice == "full_induction_programme"
  end

private

  def cip_status
    if choose_training_materials_status == "Done" && add_participants_status == "Done"
      "Done"
    else
      "To do"
    end
  end

  def fip_status
    if training_provider_status == "Done" && add_participants_status == "Done"
      "Done"
    else
      "To do"
    end
  end
end
