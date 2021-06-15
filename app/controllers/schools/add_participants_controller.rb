# frozen_string_literal: true

module Schools
  class AddParticipantsController < ::Schools::BaseController
    FORM_SESSION_KEY = :add_participant_form
    FORM_PARAM_KEY = :schools_add_participant_form

    skip_after_action :verify_authorized
    before_action :ensure_form_present, except: :start
    before_action :set_school_cohort

    helper_method :add_participant_form

    def start
      session.delete(FORM_SESSION_KEY)
      session[FORM_SESSION_KEY] = {
        school_cohort_id: @school_cohort.id,
      }
      redirect_to action: :show, step: :type
    end

    def show
      render current_step
    end

    def update
      if add_participant_form.valid?(current_step)
        add_participant_form.record_completed_step current_step
        store_form_in_session
        redirect_to action: :show, step: step_param(add_participant_form.next_step(current_step))
      else
        render current_step
      end
    end

    def complete
      @participant_profile = add_participant_form.save!
      @type = add_participant_form.type

      session.delete(FORM_SESSION_KEY)
    end

  private

    def add_participant_form
      return @add_participant_form if defined?(@add_participant_form)

      @add_participant_form = AddParticipantForm.new(session[FORM_SESSION_KEY])
      @add_participant_form.assign_attributes(add_participant_form_params) if params[FORM_PARAM_KEY]

      @add_participant_form
    end

    def store_form_in_session
      session[FORM_SESSION_KEY] = add_participant_form.attributes
    end

    def current_step
      params[:step].underscore.to_sym
    end

    def step_param(step)
      step.to_s.dasherize
    end

    def back_link_path
      if (previous_step = add_participant_form.previous_step(current_step))
        { action: :show, step: step_param(previous_step) }
      else
        participants = User.order(:full_name).is_participant.in_school(@school.id)
        participants.any? ? schools_participants_path : schools_cohort_path(id: @cohort.start_year)
      end
    end

    def add_participant_form_params
      params.require(FORM_PARAM_KEY).permit(:type, :full_name, :email, :mentor_id)
    end

    def email_used_in_the_same_school?
      User.find_by(email: add_participant_form.email).school == add_participant_form.school_cohort.school
    end

    def ensure_form_present
      redirect_to schools_participants_path unless session.key?(FORM_SESSION_KEY)
    end

    helper_method :back_link_path
    helper_method :email_used_in_the_same_school?
  end
end
