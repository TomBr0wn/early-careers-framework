# frozen_string_literal: true

require Rails.root.join("db/new_seeds/util/seed_utils")

@cohorts = Cohort.all
@lead_providers = LeadProvider.all

def add_school_to_local_authority(school:, local_authority:, nomination_email: false)
  FactoryBot.create(:seed_school_local_authority, school:, local_authority:)
  FactoryBot.create(:seed_induction_coordinator_profile, :with_user).tap do |induction_coordinator_profile|
    FactoryBot.create(:seed_induction_coordinator_profiles_school, induction_coordinator_profile:, school:)

    @cohorts.sample(@cohorts.length).each do |cohort|
      school_cohort = FactoryBot.create(:seed_school_cohort, school:, cohort:)
      if school_cohort.fip?
        induction_programme = NewSeeds::Scenarios::InductionProgrammes::Fip.new(school_cohort:)
          .build
          .with_partnership
          .induction_programme
        school_cohort.update!(default_induction_programme: induction_programme)
      elsif school_cohort.cip?
        induction_programme = NewSeeds::Scenarios::InductionProgrammes::Cip.new(school_cohort:)
          .build
          .with_core_induction_programme
          .induction_programme
        school_cohort.update!(default_induction_programme: induction_programme)
      end
    end

    @lead_providers.sample.tap do |lead_provider|
      scenarios = Random.rand(1..4).times.map do
        NewSeeds::Scenarios::Participants::Mentors::MentoringMultipleEctsWithSameProvider
          .new(school:, lead_provider:)
          .build(with_eligibility: false)
      end

      scenarios.flat_map(&:mentees).each do |participant_profile|
        Rails.logger.debug("seeding eligibility for #{participant_profile.user.full_name}")

        FactoryBot.create(:seed_ecf_participant_eligibility, random_weighted_eligibility_trait, participant_profile:)
      end
    end

    FactoryBot.create(:seed_nomination_email, :valid, sent_to: school.primary_contact_email) if nomination_email
  end
end

# create some local authorities
local_authorities = FactoryBot.create_list(:seed_local_authority, seed_quantity(:local_authorities))

# add some random schools to each LA
local_authorities.each do |local_authority|
  add_school_to_local_authority(school: FactoryBot.create(:seed_school), local_authority:)
end

# and add some with the old 'test' school format so they're easily findable in dev
1.upto(8) do |i|
  add_school_to_local_authority(
    school: FactoryBot.create(
      :seed_school,
      :with_induction_coordinator,
      urn: i.to_s.rjust(6, "0"),
      name: "ZZ Test School #{i}",
      primary_contact_email: "cpd-test+school-#{i}@digital.education.gov.uk",
    ),
    local_authority: local_authorities.sample,

    # this reimplements a feature of the legacy seeds
    # where 'ZZ Test School 3' has a NominationEmail record
    nomination_email: i == 3,
  )
end

# added some edge cases
Random.rand(1..4).times.map do
  add_school_to_local_authority(
    school: FactoryBot.create(
      :seed_school,
      :with_induction_coordinator,
      :cip_only,
    ),
    local_authority: local_authorities.sample,
  )
  add_school_to_local_authority(
    school: FactoryBot.create(
      :seed_school,
      :with_induction_coordinator,
      :ineligible,
    ),
    local_authority: local_authorities.sample,
  )
end
