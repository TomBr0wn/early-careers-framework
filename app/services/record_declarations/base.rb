# frozen_string_literal: true

require "json_schema/validate_body_against_schema"

module RecordDeclarations
  class Base
    attr_accessor :params

    delegate :user_profile, :actual_lead_provider, to: :not_implemented_error

    class << self
      delegate :required_params, to: :not_implemented_error

      def call(params)
        new(params).call
      end

      def not_implemented_error
        raise NotImplementedError, "Method must be implemented"
      end
    end

    def not_implemented_error
      self.class.not_implemented_error
    end

    def call
      validate_schema!
      validate_participant_params!

      declaration = create_record!
      validate_provider!
      { id: declaration.id }
    end

  private

    def initialize(params)
      @params = params
    end

    def validate_schema!
      errors = ::JsonSchema::ValidateBodyAgainstSchema.call(schema: schema, body: params[:raw_event])
      raise ActionController::ParameterMissing, (errors.map { |error| error.sub(/\sin schema.*$/, "") }) unless errors.empty?
    end

    def schema_validation_params
      { version: "0.3" }
    end

    def schema
      JSON.parse(File.read(::JsonSchema::VersionEventFileName.call(schema_validation_params)))
    end

    def validate_participant_params!
      raise ActionController::ParameterMissing, [I18n.t(:invalid_course)] unless course_valid_for_participant?
      raise ActionController::ParameterMissing, [I18n.t(:invalid_participant)] unless participant?
    end

    def user_id
      params[:user_id]
    end

    def course
      params[:course_identifier]
    end

    def user
      @user ||= User.find_by(id: user_id)
    end

    def course_valid_for_participant?
      self.class.valid_courses.include?(course) && user_profile
    end

    def create_record!
      ActiveRecord::Base.transaction do
        declaration_type.create!(params.slice(*self.class.required_params)).tap do |participant_declaration|
          ProfileDeclaration.create!(
            participant_declaration: participant_declaration,
            participant_profile: user_profile,
          )
        end
      end
    end

    def lead_provider_from_token
      params[:cpd_lead_provider]
    end

    def validate_provider!
      # TODO: Remove the nil? check and fix the test setup so that they build the school cohort, partnership and give us back the actual lead_provider.
      raise ActionController::ParameterMissing, I18n.t(:invalid_participant) unless actual_lead_provider.nil? || lead_provider_from_token == actual_lead_provider
    end
  end
end
