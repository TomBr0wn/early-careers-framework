# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finance::NPQ::AssuranceReportsController, :with_default_schedules do
  let(:user)                    { create(:user, :finance) }
  let(:cpd_lead_provider)       { create(:cpd_lead_provider, :with_npq_lead_provider) }
  let(:npq_lead_provider)       { cpd_lead_provider.npq_lead_provider }
  let(:statement)               { create(:npq_statement, cpd_lead_provider:) }
  let(:school)                  { create(:school, name: "A school") }
  let(:other_cpd_lead_provider) { create(:cpd_lead_provider, :with_npq_lead_provider) }
  let(:other_statement)         { create(:npq_statement, cpd_lead_provider: other_cpd_lead_provider) }

  let(:parsed_response) { CSV.parse(response.body.force_encoding("utf-8"), headers: true, encoding: "utf-8", col_sep: ",") }

  before do
    travel_to statement.deadline_date do
      @declarations = create_list(:npq_participant_declaration, 2, :eligible, cpd_lead_provider:, school_urn: school.urn)
    end
    travel_to other_statement.deadline_date do
      create_list(:npq_participant_declaration, 2, :eligible, cpd_lead_provider: other_cpd_lead_provider)
    end
    sign_in user
  end

  it "allows to download a CSV of the assurance report" do
    get finance_npq_statement_assurance_report_path(statement, format: "csv")

    content_disposition_cookie_header = Rack::Utils.parse_cookies_header(response.headers["Content-Disposition"])
    expect(content_disposition_cookie_header)
      .to include({ "filename" => "\"NPQ-Declarations-#{npq_lead_provider.name.gsub(/\W/, '')}-Cohort#{statement.cohort.start_year}-#{statement.name.gsub(/\W/, '')}.csv\"" })
  end

  it "returns the correct values in the CSV", :aggregate_failures do
    get finance_npq_statement_assurance_report_path(statement, format: "csv")

    parsed_response.each do |row|
      expect(row["Statement Name"]).to eq(statement.name)
      expect(row["Statement ID"]).to eq(statement.id)

      participant_declaration = ParticipantDeclaration.find(row["Declaration ID"])
      expect(row["Declaration Status"]).to     eq(participant_declaration.state)
      expect(row["Declaration Type"]).to       eq(participant_declaration.declaration_type)
      expect(row["Declaration Date"]).to       eq(participant_declaration.declaration_date.iso8601)
      expect(row["Declaration Created At"]).to eq(participant_declaration.created_at.iso8601)
      expect(row["Lead Provider Name"]).to     eq(participant_declaration.cpd_lead_provider.npq_lead_provider.name)

      participant_profile = participant_declaration.participant_profile
      expect(row["Participant ID"]).to   eq(participant_profile.participant_identity.external_identifier)
      expect(row["Participant Name"]).to eq(CGI.escapeHTML(participant_profile.participant_identity.user.full_name))
      expect(row["TRN"]).to              eq(participant_profile.teacher_profile.trn)
      expect(row["Schedule"]).to         eq(participant_profile.schedule.schedule_identifier)

      npq_application = participant_profile.npq_application
      expect(row["Course Identifier"]).to         eq(npq_application.npq_course.identifier)
      expect(row["School Urn"]).to                eq(npq_application.school_urn)
      expect(row["School Name"]).to               eq(school.name)
      expect(row["Targeted Delivery Funding"]).to eq(npq_application.targeted_delivery_funding_eligibility.to_s)
      expect(row["Eligible For Funding"]).to      eq("true")
    end
  end

  context "with multiple withdrawn participant profile states" do
    let(:participant_profile) { @declarations.first.participant_profile }
    let(:other_participant_profile) { @declarations.last.participant_profile }

    before do
      participant_profile.participant_profile_states.create!({ state: "withdrawn", cpd_lead_provider: })
      participant_profile.participant_profile_states.create!({ state: "withdrawn", cpd_lead_provider: })
      other_participant_profile.participant_profile_states.create!({ state: "withdrawn", cpd_lead_provider: })
      other_participant_profile.participant_profile_states.create!({ state: "withdrawn", cpd_lead_provider: })
    end

    it "does not duplicate the CSV response rows count" do
      get finance_npq_statement_assurance_report_path(statement, format: "csv")

      expect(parsed_response.length).to eql(2)
    end
  end

  context "with latest declaration status different from the one originally set for the statement" do
    before do
      @declarations.map { |declaration| declaration.statement_line_items.update_all(state: "awaiting_clawback") }
    end

    it "gets the declaration status from statement line items" do
      get finance_npq_statement_assurance_report_path(statement, format: "csv")

      parsed_response.each do |row|
        participant_declaration = ParticipantDeclaration.find(row["Declaration ID"])
        expect(row["Declaration Status"]).not_to eq(participant_declaration.state)
        expect(row["Declaration Status"]).to eql("awaiting_clawback")
      end
    end
  end
end
