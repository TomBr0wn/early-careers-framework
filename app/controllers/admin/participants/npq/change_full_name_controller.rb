# frozen_string_literal: true

module Admin::Participants::NPQ
  class ChangeFullNameController < Admin::BaseController
    before_action :load_participant
    before_action :check_gai_status

    def edit
      @full_name_form = build_full_name_form(@participant_profile, full_name: @participant_profile.user.full_name)
    end

    def update
      @full_name_form = build_full_name_form(@participant_profile, **change_full_name_params_hash)

      old_name = @participant_profile.user.full_name
      new_name = @full_name_form.full_name

      if old_name == new_name
        redirect_to(admin_participant_path(@participant_profile))
      elsif @full_name_form.save
        flash[:success] = { title: "Name changed", content: "#{old_name} was changed to #{new_name}" }

        redirect_to(admin_participant_path)
      else
        render :edit
      end
    end

  private

    def check_gai_status
      if @participant_profile.user.get_an_identity_id.present?
        flash[:alert] = "GAI users cant access this page"

        redirect_to admin_participants_path
      end
    end

    def change_full_name_params_hash
      change_full_name_params.to_h.symbolize_keys
    end

    def change_full_name_params
      params.require(:admin_participants_npq_change_full_name_form).permit(:full_name)
    end

    def build_full_name_form(participant_profile, full_name:)
      Admin::Participants::NPQ::ChangeFullNameForm.new(participant_profile.user, full_name:)
    end

    def load_participant
      @participant_profile = policy_scope(ParticipantProfile::NPQ).eager_load(:user).find(params[:participant_id]).tap do |participant_profile|
        authorize participant_profile, policy_class: participant_profile.policy_class
      end
    end
  end
end
