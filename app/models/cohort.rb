# frozen_string_literal: true

class Cohort < ApplicationRecord
  has_many :call_off_contracts
  has_many :npq_contracts
  has_many :partnerships
  has_many :schedules, class_name: "Finance::Schedule"
  has_many :statements

  # Class Methods

  # Find the cohort with start year matching the given year.
  def self.[](year)
    find_by_start_year(year)
  end

  def self.active_registration_cohort
    where(registration_start_date: ..Date.current).order(start_year: :desc).first
  end

  def self.current
    date_range = (Date.current - 1.year + 1.day)..Date.current
    where(academic_year_start_date: date_range).first
  end

  def self.next
    date_range = (Date.current + 1.day)..(Date.current + 1.year)
    where(academic_year_start_date: date_range).first
  end

  def self.previous
    date_range = (Date.current - 2.years + 1.day)..(Date.current - 1.year)
    where(academic_year_start_date: date_range).order(start_year: :desc).first
  end

  # Instance Methods

  # e.g. "2021/22"
  def academic_year
    sprintf("#{start_year}/%02d", ((start_year + 1) % 100))
  end

  # e.g. "2021 to 2022"
  def description
    "#{start_year} to #{start_year + 1}"
  end

  # e.g. "2021"
  def display_name
    start_year.to_s
  end

  def next
    Cohort[start_year + 1]
  end

  def previous
    Cohort[start_year - 1]
  end

  # e.g. "2022"
  def to_param
    start_year.to_s
  end
end
