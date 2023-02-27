# frozen_string_literal: true

class UpdateInductionTutor < BaseService
  attr_accessor :school, :email, :full_name

  def initialize(school:, email:, full_name:)
    @school = school
    @email = email
    @full_name = full_name
  end

  def call
    ActiveRecord::Base.transaction do
      @school.induction_tutor.update!(full_name: @induction_tutor_form.full_name,
                                      email: @induction_tutor_form.email)
    end
  end
end
