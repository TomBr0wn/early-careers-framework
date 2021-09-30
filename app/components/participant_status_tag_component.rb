# frozen_string_literal: true

class ParticipantStatusTagComponent < BaseComponent
  def initialize(profile:, admin: false)
    @profile = profile
    @admin = admin
  end

  def call
    if profile.npq?
      render Admin::Participants::NPQValidationStatusTag.new(profile: profile)
    else
      govuk_tag(**tag_attributes)
    end
  end

private

  attr_reader :admin, :profile

  def tag_attributes
    return { text: "Manual checks needed", colour: "turquoise" } if admin && profile.manual_check_needed?
    return { text: "DfE checking eligibility", colour: "blue" } if profile.ecf_participant_validation_data.present?
    return { text: "DfE requested details from participant", colour: "yellow" } if latest_email&.delivered?
    return { text: "Could not contact: check email address", colour: "red" } if latest_email&.failed?

    { text: "DfE to request details from participant", colour: "blue" }
  end

  def latest_email
    return @latest_email if defined?(@latest_email)

    @latest_email = Email.associated_with(profile).tagged_with(:request_for_details).latest
  end
end
