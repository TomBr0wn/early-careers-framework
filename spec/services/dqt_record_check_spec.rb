# frozen_string_literal: true

require "rails_helper"

RSpec.describe DQTRecordCheck do
  shared_context "build fake DQT response" do
    before do
      allow_any_instance_of(FullDQT::V1::Client).to(receive(:get_record).and_return(fake_api_response || default_api_response))
    end
  end

  let(:trn) { "1234567" }
  let(:nino) { "QQ123456A" }
  let(:date_of_birth) { 25.years.ago.to_date }
  let(:full_name) { "Mr Nelson Muntz" }
  let(:kwargs) { { full_name:, trn:, date_of_birth:, nino: } }
  let(:default_api_response) do
    {
      "state_name" => "Active",
      "trn" => trn,
      "name" => full_name,
      "ni_number" => nino,
      "dob" => 25.years.ago.to_date,
    }
  end
  let(:fake_api_response) { nil }

  subject { DQTRecordCheck.new(**kwargs) }

  context "when trn and national insurance number are blank" do
    let(:trn) { "" }
    let(:nino) { "" }
    include_context "build fake DQT response"

    it { expect(subject.call.failure_reason).to be(:trn_and_nino_blank) }
  end

  context "when inactive" do
    include_context "build fake DQT response" do
      let(:fake_api_response) { { "state_name" => "Inactive" } }
    end

    it { expect(subject.call.failure_reason).to be(:found_but_not_active) }
  end

  context "when active" do
    describe "matching on TRN" do
      context "when exact" do
        include_context "build fake DQT response"

        it("#trn_matches is true") { expect(subject.call.trn_matches).to be(true) }
      end

      context "when different" do
        include_context "build fake DQT response" do
          let(:fake_api_response) { default_api_response.merge("trn" => "9988776") }
        end

        it("#trn_matches is false") { expect(subject.call.trn_matches).to be(false) }
      end
    end

    describe "matching on name" do
      context "when check_first_name_only: true" do
        context "when exact" do
          include_context "build fake DQT response"

          it("#name_matches is true") { expect(subject.call.name_matches).to be(true) }
        end

        context "when there is whitespace around the supplied name" do
          let(:full_name) { " Mr Nelson Muntz  " }
          include_context "build fake DQT response"

          it("#name_matches is true") { expect(subject.call.name_matches).to be(true) }
        end

        context "when there is whitespace around the name in the API response" do
          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => " #{full_name} ") }
          end

          it("#name_matches is true") { expect(subject.call.name_matches).to be(true) }
        end

        context "when first names are different but surnames are the same" do
          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => "Mr Eddie Muntz") }
          end

          it("#name_matches is false") { expect(subject.call.name_matches).to be(false) }
        end

        context "when full_name is blank" do
          let(:full_name) { "" }

          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => "Nelson Muntz") }
          end

          it("#name_matches is false") { expect(subject.call.name_matches).to be(false) }
        end

        context "when full_name is title" do
          let(:full_name) { "mr" }

          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => "Nelson Muntz") }
          end

          it("#name_matches is false") { expect(subject.call.name_matches).to be(false) }
        end
      end

      context "when check_first_name_only: false" do
        let(:kwargs) { { full_name:, trn:, date_of_birth:, nino:, check_first_name_only: false } }

        context "when exact" do
          include_context "build fake DQT response"

          it("#name_matches is true") { expect(subject.call.name_matches).to be(true) }
        end

        context "when first names match but surnames are different" do
          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => "Mr Nelson Piquet") }
          end

          it("#name_matches is false") { expect(subject.call.name_matches).to be(false) }
        end

        context "when full_name is blank" do
          let(:full_name) { nil }

          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => "Nelson Muntz") }
          end

          it("#name_matches is false") { expect(subject.call.name_matches).to be(false) }
        end

        context "when full_name is title" do
          let(:full_name) { "mr" }

          include_context "build fake DQT response" do
            let(:fake_api_response) { default_api_response.merge("name" => "Nelson Muntz") }
          end

          it("#name_matches is false") { expect(subject.call.name_matches).to be(false) }
        end
      end
    end

    describe "matching on date of birth" do
      context "when exact" do
        include_context "build fake DQT response"

        it("#dob_matches is true") { expect(subject.call.dob_matches).to be(true) }
      end

      context "when different" do
        include_context "build fake DQT response" do
          let(:fake_api_response) { default_api_response.merge("dob" => 27.years.ago.to_date) }
        end

        it("#dob_matches is false") { expect(subject.call.dob_matches).to be(false) }
      end
    end

    describe "matching on national insurance number" do
      context "when exact" do
        include_context "build fake DQT response"

        it("#nino_matches is true") { expect(subject.call.nino_matches).to be(true) }
      end

      context "when blank" do
        include_context "build fake DQT response" do
          let(:nino) { nil }
        end

        it("#nino_matches is false") { expect(subject.call.nino_matches).to be(false) }
      end

      context "when different" do
        include_context "build fake DQT response" do
          let(:fake_api_response) { default_api_response.merge("ni_number" => "ZZ123456X") }
        end

        it("#nino_matches is false") { expect(subject.call.nino_matches).to be(false) }
      end
    end

    describe "overall match status" do
      include_context "build fake DQT response"

      context "when everything matches" do
        it("#total_matches is 4") { expect(subject.call.total_matched).to eq(4) }
        it("#failure_reason is nil") { expect(subject.call.failure_reason).to be_nil }
      end
    end

    context "when there are less than three matches excluding TRN" do
      include_context "build fake DQT response" do
        let(:fake_api_response) { default_api_response.except("dob").merge("ni_number" => "QQ121212Q") }
      end

      before do
        allow_any_instance_of(DQTRecordCheck).to receive(:check_record).and_call_original
      end

      it "sets trn to 0000001 and calls check_record again" do
        expect(subject.send(:trn)).to eql(trn)

        subject.call

        expect(subject.send(:trn)).to eql("0000001")
        expect(subject).to have_received(:check_record).twice
      end

      context "when the TRN matches and DoB or Nino but the name doesn't match (2 matches)" do
        include_context "build fake DQT response" do
          let(:fake_api_response) { default_api_response.except("dob").merge("name" => "Jimbo Jones") }
        end

        it "returns the record and match results" do
          result = subject.call
          expect(result.trn_matches).to be(true)
          expect(result.name_matches).to be(false)
          expect(result.dqt_record).to be_present
          expect(result.total_matched).to eql(2)
        end
      end
    end
  end
end
