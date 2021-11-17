# frozen_string_literal: true

RSpec.shared_context "lead provider profiles and courses", :with_default_schedule do
  # lead providers setup
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_lead_provider) }
  let(:another_lead_provider) { create(:cpd_lead_provider, :with_lead_provider, name: "Unknown") }
  let!(:default_schedule) { Finance::Schedule::ECF.default }
  # ECF setup
  let(:ecf_lead_provider) { cpd_lead_provider.lead_provider }
  let!(:ect_profile) { create(:participant_profile, :ect, schedule: default_schedule) }
  let!(:mentor_profile) { create(:participant_profile, :mentor, school_cohort: ect_profile.school_cohort, schedule: default_schedule) }
  let(:induction_coordinator_profile) { create(:induction_coordinator_profile) }
  let(:delivery_partner) { create(:delivery_partner) }
  let!(:school_cohort) { create(:school_cohort, school: ect_profile.school, cohort: ect_profile.cohort) }
  let!(:partnership) do
    create(:partnership,
           school: ect_profile.school,
           lead_provider: cpd_lead_provider.lead_provider,
           cohort: ect_profile.cohort,
           delivery_partner: delivery_partner)
  end

  # NPQ setup
  let(:npq_lead_provider) { create(:npq_lead_provider, cpd_lead_provider: cpd_lead_provider) }
  let(:npq_course) { create(:npq_course, identifier: "npq-leading-teaching") }
  let!(:npq_profile) do
    npq_application = create(
      :npq_application,
      npq_lead_provider: npq_lead_provider,
      npq_course: npq_course,
    )
    create(
      :participant_profile,
      :npq,
      npq_application: npq_application,
      user: npq_application.user,
      teacher_profile: npq_application.user.teacher_profile,
      schedule: Finance::Schedule::NPQLeadership.default,
    )
  end
end
