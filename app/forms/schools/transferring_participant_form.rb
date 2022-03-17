# frozen_string_literal: true

module Schools
  class TransferringParticipantForm
    include ActiveModel::Model
    include ActiveRecord::AttributeAssignment
    include ActiveModel::Serialization

    attr_accessor :full_name, :trn, :date_of_birth, :start_date, :email, :mentor_id, :school_cohort, :schools_current_programme_choice, :teachers_current_programme_choice, :delivery_partner_choice, :same_programme

    validates :full_name, presence: true, on: :full_name
    validates :trn,
              presence: true,
              format: { with: /\A\d+\z/ },
              length: { within: 5..7 },
              on: :trn
    validates :email, presence: true, notify_email: true, on: :email
    validates :mentor_id, presence: true, on: :choose_mentor
    validates :delivery_partner_choice, presence: true, on: :delivery_partner_choice
    validate :schools_programme_choice, on: :schools_current_programme
    validate :teachers_programme_choice, on: :teachers_current_programme
    validate :mentor, on: :choose_mentor
    validate :dob, on: :dob
    validate :teacher_start_date, on: :teacher_start_date

    def attributes
      {
        full_name: full_name,
        trn: trn,
        date_of_birth: date_of_birth,
        start_date: start_date,
        email: email,
        mentor_id: mentor_id,
        schools_current_programme_choice: schools_current_programme_choice,
        teachers_current_programme_choice: teachers_current_programme_choice,
        school_cohort: school_cohort,
        same_programme: same_programme,
      }
    end

    def full_name_to_display
      full_name.split("-").map(&:titleize).join("-") << (full_name[-1..].downcase == "s" ? "’" : "’s")
    end

    def check_against_dqt?
      full_name.present? && trn.present? && date_of_birth.present?
    end

    def schools_current_programme_choices
      [
        OpenStruct.new(id: "yes", name: "Yes"),
        OpenStruct.new(id: "no", name: "No"),
      ]
    end

    def teachers_current_programme_choices
      [
        OpenStruct.new(id: "yes", name: "Yes"),
        OpenStruct.new(id: "no", name: "No"),
      ]
    end

  private

    def teacher_start_date
      @start_date = ActiveRecord::Type::Date.new.cast(start_date)
      if @start_date.blank?
        errors.add(:start_date, I18n.t("errors.start_date.blank"))
      elsif @start_date.year.digits.length != 4
        errors.add(:start_date, I18n.t("errors.start_date.invalid"))
      end
    end

    def dob
      @date_of_birth = ActiveRecord::Type::Date.new.cast(date_of_birth)
      if date_of_birth.blank?
        errors.add(:date_of_birth, I18n.t("errors.date_of_birth.blank"))
      elsif date_of_birth > Time.zone.now
        errors.add(:date_of_birth, I18n.t("errors.date_of_birth.in_future"))
      elsif !date_of_birth.between?(Date.new(1900, 1, 1), Date.current - 18.years)
        errors.add(:date_of_birth, I18n.t("errors.date_of_birth.invalid"))
      elsif date_of_birth.year.digits.length != 4
        errors.add(:date_of_birth, I18n.t("errors.date_of_birth.invalid"))
      end
    end

    def schools_programme_choice
      errors.add(:schools_current_programme_choice, :blank) unless schools_current_programme_choices.map(&:id).include?(schools_current_programme_choice)
    end

    def teachers_programme_choice
      errors.add(:teachers_current_programme_choice, :blank) unless teachers_current_programme_choices.map(&:id).include?(teachers_current_programme_choice)
    end

    def mentor
      @mentor_id = nil if mentor_id == "later"
    end
  end
end
