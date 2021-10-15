# frozen_string_literal: true

describe FinanceHelper do
  describe "#total_payment" do
    let!(:lead_provider) { create(:lead_provider) }
    let!(:cpd_lead_provider) { create(:cpd_lead_provider, lead_provider: lead_provider) }
    let!(:contract) { create(:call_off_contract, lead_provider: cpd_lead_provider.lead_provider) }

    let(:breakdown) do
      CalculationOrchestrator.call(
        cpd_lead_provider: cpd_lead_provider,
        contract: cpd_lead_provider.lead_provider.call_off_contract,
        event_type: :started,
      )
    end

    context "when lead provider is vat chargeable" do
      it "returns the total payment for the breakddown" do
        expect(helper.total_payment(breakdown).to_i).to eq(22_287)
      end

      it "returns the total VAT for the breakddown" do
        expect(helper.total_vat(breakdown, lead_provider).to_i).to eq(4_457)
      end
    end

    context "when lead provider is not vat chargeable" do
      let!(:lead_provider) { create(:lead_provider, vat_chargeable: false) }

      it "returns the total VAT for the breakddown" do
        expect(helper.total_vat(breakdown, lead_provider).to_i).to eq(0)
      end
    end
  end

  describe "#cutoff_date" do
    milestone_dates = FinanceHelper::MILESTONE_DATES

    milestone_dates.each_with_index do |_date, index|
      Date.parse(milestone_dates[index - 1]).upto(Date.parse(milestone_dates[index]) - 1.day) do |date|
        it "returns correct milestone cutoff date" do
          travel_to(date) do
            expect(cutoff_date).to eq(Date.parse(milestone_dates[index]).strftime("%-d %B %Y"))
          end
        end

        it "returns correct payment period" do
          travel_to(date) do
            expect(payment_period).to eq(milestone_dates[index - 1, 2])
          end
        end
      end
    end
  end
end
