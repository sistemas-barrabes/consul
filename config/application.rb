require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Consul
  class Application < Rails::Application
    config.load_defaults 6.0

    # Keep belongs_to fields optional by default, because that's the way
    # Rails 4 models worked
    config.active_record.belongs_to_required_by_default = false

    # Use local forms with `form_with`, so it works like `form_for`
    config.action_view.form_with_generates_remote_forms = false

    # Keep using AES-256-CBC for message encryption in case it's used
    # in any CONSUL installations
    config.active_support.use_authenticated_message_encryption = false

    # Keep using the classic autoloader until we decide how custom classes
    # should work with zeitwerk
    config.autoloader = :classic

    # Use the default queue for ActiveStorage like we were doing with Rails 5.2
    # because it will also be the default in Rails 6.1.
    config.active_storage.queues.analysis = nil
    config.active_storage.queues.purge    = nil

    # Keep reading existing data in the legislation_annotations ranges column
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess, Symbol]

    # Handle custom exceptions
    config.action_dispatch.rescue_responses["FeatureFlags::FeatureDisabled"] = :forbidden
    config.action_dispatch.rescue_responses["Apartment::TenantNotFound"] = :not_found

    # Store uploaded files on the local file system (see config/storage.yml for options).
    config.active_storage.service = :local

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    available_locales = [
      "ar",
      "bg",
      "bs",
      "ca",
      "cs",
      "da",
      "de",
      "el",
      "en",
      "es",
      "es-PE",
      "eu",
      "fa",
      "fr",
      "gl",
      "he",
      "hr",
      "id",
      "it",
      "ka",
      "nl",
      "oc",
      "pl",
      "pt-BR",
      "ro",
      "ru",
      "sl",
      "sq",
      "so",
      "sr",
      "sv",
      "tr",
      "uk-UA",
      "val",
      "zh-CN",
      "zh-TW"]
    config.i18n.available_locales = available_locales
    config.i18n.fallbacks = [I18n.default_locale, {
      "ca"    => "es",
      "es-PE" => "es",
      "eu"    => "es",
      "fr"    => "es",
      "gl"    => "es",
      "it"    => "es",
      "oc"    => "fr",
      "pt-BR" => "es",
      "val"   => "es"
    }]

    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**[^custom]*", "*.{rb,yml}")]
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "custom", "**", "*.{rb,yml}")]

    config.after_initialize do
      Globalize.set_fallbacks_to_all_available_locales
    end

    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.paths << Rails.root.join("vendor", "assets", "fonts")

    # Add lib to the autoload path
    config.autoload_paths << Rails.root.join("lib")
    config.time_zone = "Madrid"
    config.active_job.queue_adapter = :delayed_job

    # CONSUL specific custom overrides
    # Read more on documentation:
    # * English: https://github.com/consul/consul/blob/master/CUSTOMIZE_EN.md
    # * Spanish: https://github.com/consul/consul/blob/master/CUSTOMIZE_ES.md
    #
    config.autoload_paths << "#{Rails.root}/app/components/custom"
    config.autoload_paths << "#{Rails.root}/app/controllers/custom"
    config.autoload_paths << "#{Rails.root}/app/graphql/custom"
    config.autoload_paths << "#{Rails.root}/app/models/custom"
    config.paths["app/views"].unshift(Rails.root.join("app", "views", "custom"))

    # Set to true to enable managing different tenants using the same application
    config.multitenancy = Rails.application.secrets.multitenancy
  end
end

class Rails::Engine
  initializer :prepend_custom_assets_path, group: :all do |app|
    if self.class.name == "Consul::Application"
      %w[images fonts].each do |asset|
        app.config.assets.paths.unshift(Rails.root.join("app", "assets", asset, "custom").to_s)
      end
    end
  end
end

require "./config/application_custom"
