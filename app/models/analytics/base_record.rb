# frozen_string_literal: true

module Analytics
  class BaseRecord < ApplicationRecord
    self.abstract_class = true

    # FIXME: remove deployed_development when we've switched to Azure
    if ENV.key?("VCAP_APPLICATION")
      connects_to database: { writing: :analytics } if %w[test development production].include? Rails.env
    else
      connects_to database: { writing: :analytics } unless Rails.env.review? || Rails.env.deployed_development?
    end
  end
end
