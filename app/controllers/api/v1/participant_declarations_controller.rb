# frozen_string_literal: true

module Api
  module V1
    class ParticipantDeclarationsController < Api::ApiController
      include ApiAuditable
      include ApiTokenAuthenticatable
      include ApiPagination
      include ApiCsv

      def create
        params = HashWithIndifferentAccess.new({ cpd_lead_provider: cpd_lead_provider }).merge(permitted_params["attributes"] || {})
        render json: RecordParticipantDeclaration.call(params)
      end

      def index
        respond_to do |format|
          format.json do
            participant_declarations_hash = ParticipantDeclarationSerializer.new(paginate(participant_declarations)).serializable_hash
            render json: participant_declarations_hash.to_json
          end
          format.csv do
            participant_declarations_hash = ParticipantDeclarationSerializer.new(participant_declarations).serializable_hash
            render body: to_csv(participant_declarations_hash)
          end
        end
      end

    private

      def cpd_lead_provider
        current_user
      end

      def participant_declarations
        ParticipantDeclaration.for_lead_provider(cpd_lead_provider)
      end

      def permitted_params
        params.require(:data).permit(:type, attributes: {})
      rescue ActionController::ParameterMissing => e
        if e.param == :data
          raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
        else
          raise
        end
      end
    end
  end
end
