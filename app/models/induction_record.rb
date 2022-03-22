# frozen_string_literal: true

class InductionRecord < ApplicationRecord
  has_paper_trail

  belongs_to :induction_programme
  belongs_to :participant_profile, class_name: "ParticipantProfile::ECF"
  belongs_to :schedule, class_name: "Finance::Schedule"
  belongs_to :mentor_profile, class_name: "ParticipantProfile::Mentor", optional: true

  has_one :school_cohort, through: :induction_programme
  has_one :school, through: :school_cohort
  has_one :user, through: :participant_profile

  # optional while the data is setup
  # enables a different identity/email to be used for this induction
  # rather that the one tied to the participant_profile
  # This is needed to allow us to display the right email in the dashboard
  # and to enable participants transferring between schools (where they might be added with
  # a different email address) to still appear correctly at their old and new schools
  # and still be able to access CIP materials while moving
  belongs_to :preferred_identity, class_name: "ParticipantIdentity", optional: true

  validates :start_date, presence: true

  enum induction_status: {
    active: "active",
    withdrawn: "withdrawn",
    changed: "changed",
    leaving: "leaving",
    completed: "completed",
  }, _suffix: true

  enum training_status: {
    active: "active",
    deferred: "deferred",
    withdrawn: "withdrawn",
  }, _prefix: "training_status"

  scope :fip, -> { joins(:induction_programme).merge(InductionProgramme.full_induction_programme) }
  scope :cip, -> { joins(:induction_programme).merge(InductionProgramme.core_induction_programme) }

  scope :active, -> { active_induction_status.where("start_date < ? AND (end_date IS NULL OR end_date > ?)", Time.zone.now, Time.zone.now) }
  scope :current, -> { active.or(transferring_out) }
  scope :transferring_in, -> { active_induction_status.where("start_date > ?", Time.zone.now) }
  scope :transferring_out, -> { leaving_induction_status.where("end_date > ?", Time.zone.now) }
  scope :transferred, -> { leaving_induction_status.where("end_date < ?", Time.zone.now) }

  scope :for_school, ->(school) { joins(:school).where(school: { id: school.id }) }

  def self.latest
    order(created_at: :asc).last
  end

  def enrolled_in_fip?
    induction_programme.full_induction_programme?
  end

  def enrolled_in_cip?
    induction_programme.core_induction_programme?
  end

  def changing!(date_of_change = Time.zone.now)
    update!(induction_status: :changed, end_date: date_of_change)
  end

  def withdrawing!(date_of_change = Time.zone.now)
    update!(induction_status: :withdrawn, end_date: date_of_change)
  end

  def leaving!(date_of_change = Time.zone.now)
    update!(induction_status: :leaving, end_date: date_of_change)
  end

  def transferring_in?
    active_induction_status? && start_date > Time.zone.now
  end

  def transferring_out?
    leaving_induction_status? && end_date.present? && end_date > Time.zone.now
  end

  def transferred?
    leaving_induction_status? && end_date.present? && end_date < Time.zone.now
  end
end
