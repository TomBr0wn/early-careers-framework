# frozen_string_literal: true

require "payment_calculator/ecf/payment_calculation"

module Finance
  module ECF
    class CalculationOrchestrator
      class << self
        def call(cpd_lead_provider:,
                 contract:,
                 aggregator: ::ParticipantEventAggregator,
                 calculator: ::PaymentCalculator::ECF::PaymentCalculation,
                 event_type: :started)
          new(
            cpd_lead_provider: cpd_lead_provider,
            contract: contract,
            aggregator: aggregator,
            calculator: calculator,
          ).call(event_type: event_type)
        end
      end

      def call(event_type:)
        aggregator.call(event_type: :none)
        calculator.call(contract: contract, aggregations: aggregator.call(event_type: event_type), event_type: event_type)
      end

    private

      attr_reader :cpd_lead_provider, :contract, :aggregator, :calculator

      def initialize(cpd_lead_provider:,
                     contract:,
                     aggregator: ::ParticipantEventAggregator,
                     calculator: ::PaymentCalculator::ECF::PaymentCalculation)
        @cpd_lead_provider = cpd_lead_provider
        @contract = contract
        @aggregator = aggregator.new(cpd_lead_provider: cpd_lead_provider)
        @calculator = calculator
      end
    end
  end
end
