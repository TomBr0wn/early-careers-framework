# frozen_string_literal: true

DfE::Analytics.configure do |config|
  # Whether to log events instead of sending them to BigQuery.
  #
  # config.log_only = true

  # Whether to use ActiveJob or dispatch events immediately.
  #
  # config.async = true

  # Which ActiveJob queue to put events on
  #
  config.queue = :dfe_analytics

  # The name of the BigQuery table we’re writing to.
  #
  # config.bigquery_table_name = ENV['BIGQUERY_TABLE_NAME']

  # The name of the BigQuery project we’re writing to.
  #
  # config.bigquery_project_id = ENV['BIGQUERY_PROJECT_ID']

  # The name of the BigQuery dataset we're writing to.
  #
  config.bigquery_dataset = ENV["BIGQUERY_DFE_ANALYTICS_DATASET"] || Rails.application.credentials.BIGQUERY_DFE_ANALYTICS_DATASET

  # Service account JSON key for the BigQuery API. See
  # https://cloud.google.com/bigquery/docs/authentication/service-account-file
  #
  config.bigquery_api_json_key = ENV["BIGQUERY_DFE_ANALYTICS_API_JSON_KEY"] || Rails.application.credentials.BIGQUERY_DFE_ANALYTICS_JSON_API_KEY

  # Passed directly to the retries: option on the BigQuery client
  #
  # config.bigquery_retries = 3

  # Passed directly to the timeout: option on the BigQuery client
  #
  # config.bigquery_timeout = 120

  # A proc which returns true or false depending on whether you want to
  # enable analytics. You might want to hook this up to a feature flag or
  # environment variable.
  #
  config.enable_analytics = proc { FeatureFlag.active?(:dfe_analytics) }

  # The environment we’re running in. This value will be attached
  # to all events we send to BigQuery.
  #
  # config.environment = ENV.fetch('RAILS_ENV', 'development')

  # A proc which will be called with the user object, and which should
  # return the identifier for the user. This is useful for systems with
  # users that don't use the id field.
  #
  # config.user_identifier = proc { |user| user&.id }
end
