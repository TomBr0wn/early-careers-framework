# frozen_string_literal: true

require "rails_helper"

RSpec.describe "NPQ profiles api endpoint", type: :request do
  let(:token) { NPQRegistrationApiToken.create_with_random_token! }
  let(:bearer_token) { "Bearer #{token}" }
  let(:parsed_response) { JSON.parse(response.body) }

  describe "#create" do
    let(:user) { create(:user) }
    let(:npq_lead_provider) { create(:npq_lead_provider) }
    let(:npq_course) { create(:npq_course) }

    context "when authorized" do
      before do
        default_headers[:Authorization] = bearer_token
        default_headers["Content-Type"] = "application/vnd.api+json"
      end

      let(:json) do
        {
          data: {
            type: "npq_profiles",
            attributes: {
              teacher_reference_number: "1234567",
              teacher_reference_number_verified: true,
              active_alert: true,
              date_of_birth: "1990-12-13",
              school_urn: "123456",
              headteacher_status: "no",
              eligible_for_funding: true,
              funding_choice: "school",
            },
            relationships: {
              user: {
                data: {
                  type: "users",
                  id: user.id,
                },
              },
              npq_lead_provider: {
                data: {
                  type: "npq_lead_providers",
                  id: npq_lead_provider.id,
                },
              },
              npq_course: {
                data: {
                  type: "npq_courses",
                  id: npq_course.id,
                },
              },
            },
          },
        }.to_json
      end

      it "creates the npq_profile" do
        expect {
          post "/api/v1/npq-profiles", params: json
        }.to change(NPQProfile, :count).by(1)

        profile = NPQProfile.order(created_at: :desc).first

        expect(profile.user).to eql(user)
        expect(profile.npq_lead_provider).to eql(npq_lead_provider)
        expect(profile.date_of_birth).to eql(Date.new(1990, 12, 13))
        expect(profile.teacher_reference_number).to eql("1234567")
        expect(profile.teacher_reference_number_verified).to be_truthy
        expect(profile.active_alert).to be_truthy
        expect(profile.school_urn).to eql("123456")
        expect(profile.headteacher_status).to eql("no")
        expect(profile.npq_course).to eql(npq_course)
        expect(profile.eligible_for_funding).to eql(true)
        expect(profile.funding_choice).to eql("school")
      end

      it "returns a 201" do
        post "/api/v1/npq-profiles", params: json
        expect(response).to be_created
      end

      it "returns correct jsonapi content type header" do
        post "/api/v1/npq-profiles", params: json
        expect(response.headers["Content-Type"]).to eql("application/vnd.api+json")
      end

      it "returns correct type" do
        post "/api/v1/npq-profiles", params: json
        expect(parsed_response["data"]).to have_type("npq_profiles")
      end

      it "response has correct attributes" do
        post "/api/v1/npq-profiles", params: json

        profile = NPQProfile.order(created_at: :desc).first

        expect(parsed_response["data"]["id"]).to eql(profile.id)
        expect(parsed_response["data"]).to have_jsonapi_attributes(
          :teacher_reference_number,
          :headteacher_status,
          :date_of_birth,
          :school_urn,
          :eligible_for_funding,
          :funding_choice,
        )
      end
    end

    context "when unauthorized" do
      it "returns 401" do
        default_headers[:Authorization] = "Bearer ugLPicDrpGZdD_w7hhCL"
        post "/api/v1/npq-profiles"
        expect(response.status).to eq 401
      end
    end

    context "using valid token but for different scope" do
      let(:other_token) { ApiToken.create_with_random_token! }

      it "returns 403" do
        default_headers[:Authorization] = "Bearer #{other_token}"
        post "/api/v1/npq-profiles"
        expect(response.status).to eq 403
      end
    end
  end
end
