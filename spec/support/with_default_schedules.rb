# frozen_string_literal: true

RSpec.shared_context "with default schedules", shared_context: :metadata do
  before do
    # create cohorts since 2020 with default schedule
    (2020..Date.current.year).each do |start_year|
      cohort = Cohort[start_year] || create(:cohort, start_year:)
      Finance::Schedule::ECF.default_for(cohort:) || create(:ecf_schedule, cohort:)
    end

    # create extra schedules for the current cohort
    cohort = Cohort.current
    {
      npq_specialist_schedule: "npq-specialist-spring",
      npq_leadership_schedule: "npq-leadership-spring",
      npq_aso_schedule:        "npq-aso-december",
      npq_ehco_schedule:       "npq-ehco-december",
    }.each do |schedule_type, schedule_identifier|
      Finance::Schedule.find_by(cohort:, schedule_identifier:) || create(schedule_type, cohort:)
    end
  end
end

RSpec.configure do |config|
  config.include_context "with default schedules", :with_default_schedules
end
