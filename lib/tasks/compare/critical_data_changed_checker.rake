# frozen_string_literal: true

require "json-diff"

Row = Struct.new(
  :induction_record,
  :participant_profile_id,
  :past_lead_provider_ids,
  :past_delivery_partner_ids,
  keyword_init: true,
) do
  def changed_lead_provider
    ([induction_record&.lead_provider&.id] + past_lead_provider_ids).compact.uniq.count > 1
  end

  def changed_delivery_partner
    ([induction_record&.delivery_partner&.id] + past_delivery_partner_ids).compact.uniq.count > 1
  end

  def to_h
    { participant_profile_id:, changed_lead_provider: }
  end
end

namespace :compare do
  namespace :critical_data_changed_checker do
    desc "compare"
    task run: :environment do
      rows = []

      InductionRecord.end_date_null.limit(50).find_in_batches.each do |batch|
        batch.each do |induction_record|
          previous_versions = InductionRecord
            .where(participant_profile_id: induction_record.participant_profile_id)
            .where(InductionRecord.arel_table[:created_at].gteq(Date.new(2022, 9, 1)))
            .where.not(id: induction_record.id)

          row = Row.new(induction_record: induction_record, participant_profile_id: induction_record.participant_profile_id)

          # Lead Provider
          row.past_lead_provider_ids = previous_versions.map { |pv| pv&.lead_provider&.id }

          # Delivery Partner
          row.past_delivery_partner_ids = previous_versions.map { |pv| pv&.delivery_partner&.id }

          # school,
          # cohort,
          # induction_start_date,
          # validated TRN,
          # funding eligibility,
          # external_id

          rows << row
        end
      end

      puts rows.map(&:to_h)
    end
  end
end
