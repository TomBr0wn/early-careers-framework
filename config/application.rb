# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

require "govuk/components"

require "friendly_id"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EarlyCareerFramework
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.exceptions_app = routes
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden

    config.active_job.queue_adapter = :sidekiq

    config.middleware.use Rack::Deflater

    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    config.record_emails = true

    Dir.glob(Rails.root.join("app/middlewares/*.rb")).sort.each do |file|
      require file
    end
  end
end
