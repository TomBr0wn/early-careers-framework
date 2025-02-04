# frozen_string_literal: true

module GiasHelpers
  extend ActiveSupport::Concern
  include GiasTypes

  included do
    scope :currently_open, -> { where(school_status_code: GiasTypes::ELIGIBLE_STATUS_CODES) }
    scope :eligible_establishment_type, -> { where(school_type_code: GiasTypes::ELIGIBLE_TYPE_CODES) }
    scope :in_england, -> { where("administrative_district_code ILIKE 'E%' OR administrative_district_code = '9999'") }
    scope :section_41, -> { where(section_41_approved: true) }
    scope :eligible, -> { currently_open.eligible_establishment_type.in_england.or(currently_open.in_england.section_41) }
    scope :cip_only, -> { currently_open.where(school_type_code: GiasTypes::CIP_ONLY_TYPE_CODES) }
    scope :eligible_or_cip_only, -> { eligible.or(cip_only) }
    scope :not_cip_only, -> { where.not(id: cip_only) }

    enum school_status_name: {
      open: "Open",
      closed: "Closed",
      proposed_to_close: "Open, but proposed to close",
      proposed_to_open: "Proposed to open",
    }, _suffix: "status"
  end

  def name_and_urn
    "#{name} (#{urn})"
  end

  def full_address
    [address_line1, address_line2, address_line3, postcode].compact_blank.join("\n")
  end

  def open?
    open_status_code?(school_status_code)
  end

  def closed?
    !open_status_code?(school_status_code)
  end

  def eligible_establishment_type?
    eligible_establishment_code?(school_type_code)
  end

  def in_england?
    english_district_code?(administrative_district_code)
  end
end
