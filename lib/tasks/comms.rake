# frozen_string_literal: true

require "csv"

namespace :comms do
  desc "Chase pilot schools"
  task :send_pilot_chaser, [:path_to_csv] => :environment do |_task, args|
    logger = Logger.new($stdout)

    rows = CSV.read(args.path_to_csv, headers: true)

    rows.each do |school|
      logger.info "Processing school with URN: #{school["urn"]}"

      school = School.find_by_urn(school["urn"])

      if school.nil?
        logger.error "Unable to find the school"
        next
      end

      if school.induction_coordinators.any?
        # Do not chase the school if there is a 2023 training programme
        if school.school_cohorts.for_year(2023).first&.induction_programme_choice
          logger.info "School has reported the training programme"
          next
        end

        school.induction_coordinators.each do |sit_user|
          if Email.tagged_with(:pilot_chase_sit_to_report_school_training_details).associated_with(sit_user).any?
            logger.info "The user has been already contacted"
            next
          end

          logger.info "Sending chaser email to the school's SIT with user id: #{sit_user.id}"
          nomination_token = create_nomination_token(school, sit_user.email)
          SchoolMailer
            .with(
              sit_user:,
              nomination_link: get_sit_nomination_url(token: nomination_token),
            )
            .pilot_chase_sit_to_report_school_training_details
            .deliver_later
        end
      else
        # Do not chase the school if the GIAS contact has already nominated a SIT
        if school.induction_coordinators.any?
          logger.info "The GIAS contact has already nominated a SIT"
          next
        end

        if Email.tagged_with(:pilot_chase_gias_contact_to_report_school_training_details).associated_with(school).any?
          logger.info "The school's primary GIAS has been already contacted"
          next
        end

        logger.info "Sending chaser to the school's primary GIAS contact"
        nomination_token = create_nomination_token(school, school.primary_contact_email)
        SchoolMailer
          .with(
            school:,
            gias_contact_email: school.primary_contact_email,
            nomination_link: get_gias_nomination_url(token: nomination_token),
          )
          .pilot_chase_gias_contact_to_report_school_training_details
          .deliver_later
      end
    end
  end
end

def get_sit_nomination_url(token:)
  Rails
    .application
    .routes
    .url_helpers
    .start_nominate_induction_coordinator_url(token:, host: Rails.application.config.domain)
end

def get_gias_nomination_url(token:)
  Rails
    .application
    .routes
    .url_helpers
    .start_nomination_nominate_induction_coordinator_url(token:, host: Rails.application.config.domain)
end

def create_nomination_token(school, email_address)
  NominationEmail.create_nomination_email(
    sent_at: Time.zone.now,
    sent_to: email_address,
    school:,
  ).token
end
