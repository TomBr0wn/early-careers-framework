# frozen_string_literal: true

require "rails_helper"

RSpec.describe "participant-declarations endpoint spec", type: :request do
  describe "post" do
    let(:cpd_lead_provider) { create(:cpd_lead_provider, lead_provider: lead_provider) }
    let(:lead_provider) { create(:lead_provider) }
    let(:token) { LeadProviderApiToken.create_with_random_token!(cpd_lead_provider: cpd_lead_provider) }
    let(:bearer_token) { "Bearer #{token}" }
    let(:payload) { create(:early_career_teacher_profile) }
    let(:delivery_partner) { create(:delivery_partner) }
    let!(:school_cohort) { create(:school_cohort, school: payload.school, cohort: payload.cohort) }
    let!(:partnership) do
      create(:partnership,
             school: payload.school,
             lead_provider: lead_provider,
             cohort: payload.cohort,
             delivery_partner: delivery_partner)
    end
    let(:valid_params) do
      {
        participant_id: payload.user_id,
        declaration_type: "started",
        declaration_date: (Time.zone.now - 1.week).iso8601,
        course_identifier: "ecf-induction",
      }
    end

    let(:invalid_user_id) do
      valid_params.merge({ participant_id: payload.id })
    end
    let(:incorrect_course_identifier) do
      valid_params.merge({ course_identifier: "typoed-course-name" })
    end
    let(:invalid_course_identifier) do
      valid_params.merge({ course_identifier: "ecf-mentor" })
    end
    let(:missing_user_id) do
      valid_params.merge({ participant_id: "" })
    end
    let(:missing_attribute) do
      valid_params.except(:participant_id)
    end

    let(:parsed_response) { JSON.parse(response.body) }

    def build_params(attributes)
      {
        data: {
          type: "participant-declaration",
          attributes: attributes,
        },
      }.to_json
    end

    context "when authorized" do
      let(:parsed_response) { JSON.parse(response.body) }

      before do
        default_headers[:Authorization] = bearer_token
        default_headers[:CONTENT_TYPE] = "application/json"
      end

      it "create declaration record and return id when successful" do
        expect {
          post "/api/v1/participant-declarations", params: build_params(valid_params)
        }.to change(ParticipantDeclaration, :count).by(1)
        expect(response.status).to eq 200
        expect(parsed_response["id"]).to eq(ParticipantDeclaration.order(:created_at).last.id)
      end

      it "returns 422 when trying to create for an invalid user id" do # Expects the user uuid. Pass the early_career_teacher_profile_id
        post "/api/v1/participant-declarations", params: build_params(invalid_user_id)
        expect(response.status).to eq 422
      end

      it "returns 422 when trying to create with no id" do
        post "/api/v1/participant-declarations", params: build_params(missing_user_id)
        expect(response.status).to eq 422
      end

      it "returns 422 when a required parameter is missing" do
        post "/api/v1/participant-declarations", params: build_params(missing_attribute)
        expect(response.status).to eq 422
        expect(response.body).to eq({ bad_or_missing_parameters: %w[participant_id] }.to_json)
      end

      it "returns 422 when supplied an incorrect course type" do
        post "/api/v1/participant-declarations", params: build_params(incorrect_course_identifier)
        expect(response.status).to eq 422
      end

      it "returns 422 when a participant type doesn't match the course type" do
        post "/api/v1/participant-declarations", params: build_params(invalid_course_identifier)
        expect(response.status).to eq 422
        expect(response.body).to eq({ bad_or_missing_parameters: ["The property '#/course_identifier' must be an available course to '#/participant_id'"] }.to_json)
      end

      it "returns 400 when the data block is incorrect" do
        post "/api/v1/participant-declarations", params: {}.to_json
        expect(response.status).to eq 400
        expect(response.body).to eq({ bad_request: I18n.t(:invalid_data_structure) }.to_json)
      end
    end

    context "when unauthorized" do
      it "returns 401 for invalid bearer token" do
        default_headers[:Authorization] = "Bearer ugLPicDrpGZdD_w7hhCL"
        post "/api/v1/participant-declarations", params: build_params(valid_params)
        expect(response.status).to eq 401
      end
    end
  end
end
