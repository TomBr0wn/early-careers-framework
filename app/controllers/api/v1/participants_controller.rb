# frozen_string_literal: true

module Api
  module V1
    class ParticipantsController < Api::ApiController
      include ApiTokenAuthenticatable
      include Pagy::Backend

      before_action :ensure_lead_provider
      skip_before_action :set_jsonapi_content_type_header

      def index
        respond_to do |format|
          format.json { render json: ParticipantSerializer.new(paginate(participants)).serializable_hash.to_json }
          format.csv { render body: "Not Implemented", status: :not_implemented }
        end
      end

    private

      def ensure_lead_provider
        head :forbidden unless current_user.class == LeadProvider
      end

      def updated_since
        params[:updated_since]
      end

      def participants
        participants = User.participants_for_lead_provider(current_user)
                           .includes(
                             early_career_teacher_profile: %i[cohort mentor school],
                             mentor_profile: %i[cohort school],
                           )

        if updated_since.present?
          participants = participants.changed_since(updated_since)
        end

        participants
      end

      def paginate(scope)
        _pagy, paginated_records = pagy(scope, items: per_page, page: page)

        paginated_records
      end

      def per_page
        params[:page] ||= {}

        [(params.dig(:page, :per_page) || default_per_page).to_i, max_per_page].min
      end

      def default_per_page
        100
      end

      def max_per_page
        100
      end

      def page
        params[:page] ||= {}
        (params.dig(:page, :page) || 1).to_i
      end
    end
  end
end
