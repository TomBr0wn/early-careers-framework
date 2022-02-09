# frozen_string_literal: true

class Finance::Statement < ApplicationRecord
  include FinanceHelper

  self.table_name = "statements"

  belongs_to :cpd_lead_provider

  has_many :participant_declarations
  scope :payable, -> { where("payment_date >= ?", Date.current) }
  scope :closed,  -> { where("payment_date < ?", Date.current) }
  scope :current, -> { where("deadline_date < DATE(NOW()) AND payment_date >= DATE(NOW())") }
  scope :upto_current, -> { payable.or(closed).or(current) }

  def open?
    payment_date > Time.current
  end

  def current?
    payment_date > Time.current && deadline_date > Time.current
  end
end
require "finance/statement/ecf"
require "finance/statement/npq"
