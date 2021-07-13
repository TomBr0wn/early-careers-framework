# frozen_string_literal: true

require "csv"

module Api
  module V1
    class NPQApplicationsController < Api::ApiController
      include ApiTokenAuthenticatable
      include ApiPagination

      def index
        respond_to do |format|
          format.json do
            render json: NpqApplicationSerializer.new(paginate(scope)).serializable_hash
          end

          format.csv do
            render body: NpqApplicationCsvSerializer.new(scope).call
          end
        end
      end

    private

      def npq_lead_provider
        current_api_token.cpd_lead_provider.npq_lead_provider
      end

      def scope
        npq_lead_provider.npq_profiles.includes(:user, :npq_course)
      end

      def access_scope
        LeadProviderApiToken.all
      end
    end
  end
end
