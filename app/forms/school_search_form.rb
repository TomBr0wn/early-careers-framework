# frozen_string_literal: true

class SchoolSearchForm
  include ActiveModel::Model

  attr_accessor :school_name, :location, :search_distance, :search_distance_unit, :characteristics, :partnership

  def find_schools
    School.where("lower(name) like ?", "%#{(school_name || '').downcase}%").includes(:network)
  end
end
