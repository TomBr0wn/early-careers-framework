# frozen_string_literal: true

class ParticipantProfile < ApplicationRecord
  belongs_to :user
  belongs_to :school, optional: true
  has_many :validation_decisions, class_name: "ProfileValidationDecision"

  enum status: {
    active: "active",
    withdrawn: "withdrawn",
  }

  scope :mentors, -> { where(type: Mentor.name) }
  scope :ects, -> { where(type: ECT.name) }
  scope :npqs, -> { where(type: NPQ.name) }

  scope :sparsity, -> { where(sparsity_uplift: true) }
  scope :pupil_premium, -> { where(pupil_premium_uplift: true) }
  scope :uplift, -> { sparsity.or(pupil_premium) }

  attr_reader :participant_type

  class_attribute :validation_steps
  self.validation_steps = []

  def ect?
    false
  end

  def mentor?
    false
  end

  def npq?
    false
  end

  def approved?
    false
  end

  def rejected?
    false
  end

  def pending?
    !approved? && !rejected?
  end

  def validation_decision(name)
    unless self.class.validation_steps.include?(name.to_sym)
      raise "Unknown validation step: #{name} for #{self.class.name}. Known steps: #{self.class.validation_steps.join(', ')}"
    end

    decision = validation_decisions.find { |record| record.validation_step.to_s == name.to_s }
    decision || validation_decisions.build(validation_step: name)
  end
end
