# frozen_string_literal: true

class WizardStep
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  include ActiveModel::Validations::Callbacks

  attr_accessor :wizard

  def self.permitted_params
    []
  end

  def previous_step
    raise NotImplementedError
  end

  def next_step
    raise NotImplementedError
  end

  def journey_complete?
    false
  end

  def revisit_next_step?
    false
  end

  def before_render; end
  def after_render; end

  def before_save; end
  def after_save; end

  def attributes
    self.class.permitted_params.index_with do |key|
      public_send(key)
    end
  end
end
