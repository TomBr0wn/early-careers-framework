# frozen_string_literal: true

module NewSeeds
  module Scenarios
    module Participants
      module Ects
        class Ect
          attr_reader :participant_profile,
                      :participant_identity,
                      :school_cohort,
                      :teacher_profile,
                      :user

          def initialize(school_cohort:, full_name: nil, email: nil)
            @school_cohort = school_cohort
            @new_user_attributes = { full_name:, email: }.compact
          end

          def build(**_profile_args)
            @user = FactoryBot.create(:seed_user, **new_user_attributes)
            @teacher_profile = FactoryBot.create(:seed_teacher_profile, user:, school: school_cohort.school)
            @participant_identity = FactoryBot.create(:seed_participant_identity, user:)
            @participant_profile = FactoryBot.create(:seed_ect_participant_profile,
                                                     participant_identity:,
                                                     teacher_profile:,
                                                     school_cohort:)

            self
          end

          def with_induction_record(**induction_args)
            add_induction_record(**induction_args)
            self
          end

          def add_induction_record(induction_programme:, mentor_profile: nil, start_date: 6.months.ago, end_date: nil, induction_status: "active", training_status: "active", preferred_identity: nil)
            preferred_identity ||= FactoryBot.create(:seed_participant_identity, user: participant_profile.user)

            schedule = Finance::Schedule::ECF.default_for(cohort: induction_programme.cohort)
            participant_profile.update!(schedule:)

            FactoryBot.create(
              :seed_induction_record,
              induction_programme:,
              mentor_profile:,
              participant_profile:,
              preferred_identity:,
              schedule:,
              start_date:,
              end_date:,
              induction_status:,
              training_status:,
            )
          end

          def with_validation_data(**args)
            add_validation_data(**args)

            self
          end

          def add_validation_data(**args)
            validation_data = { full_name: args[:full_name] || user.full_name,
                                trn: args[:trn] || teacher_profile.trn,
                                date_of_birth: args[:date_of_birth],
                                nino: args[:nino],
                                participant_profile: }

            FactoryBot.create(:seed_ecf_participant_validation_data, **validation_data.compact)
          end

          def with_eligibility(**args)
            add_eligibility(**args)

            self
          end

          def add_eligibility(**args)
            eligibility_data = { qts: args[:qts],
                                 active_flags: args[:active_flags],
                                 previous_participation: args[:previous_participation],
                                 previous_induction: args[:previous_induction],
                                 no_induction: args[:no_induction],
                                 status: args[:status],
                                 reason: args[:reason],
                                 participant_profile: }

            FactoryBot.create(:seed_ecf_participant_eligibility, **eligibility_data.compact)
          end

          def with_becoming_a_mentor(mentor_school_cohort:, mentor_induction_programme:)
            Mentors::MentorWithNoEcts
              .new(
                school_cohort: mentor_school_cohort,
                participant_identity:,
                teacher_profile:,
              )
              .build(schedule: Finance::Schedule::ECF.default_for(cohort: mentor_school_cohort.cohort))
              .with_validation_data
              .with_eligibility
              .with_induction_record(induction_programme: mentor_induction_programme)
          end

        private

          attr_reader :new_user_attributes
        end
      end
    end
  end
end
