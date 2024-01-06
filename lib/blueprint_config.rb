# frozen_string_literal: true

require 'blueprint_config/version'
require 'blueprint_config/backend/env'
require 'blueprint_config/backend/yaml'
require 'blueprint_config/configuration'
require 'blueprint_config/backend_collection'

module BlueprintConfig
  class << self
    attr_accessor :root, :env, :before_initialize, :after_initialize
    attr_writer :shortcut_name, :env_options

    def shortcut_name
      @shortcut_name || 'AppConfig'
    end

    def env_options
      @env_options || {}
    end

    def define_shortcut
      Object.const_set shortcut_name, instance
    end

    def instance
      BlueprintConfig::Configuration.instance
    end

    def init
      before_initialize&.call
    end

    def configure_rails(config)
      config.before_configuration do |_app|
        BlueprintConfig.root ||= Rails.root
        BlueprintConfig.env ||= Rails.env
        BlueprintConfig.define_shortcut
        BlueprintConfig.before_initialize.call
      end

      config.after_initialize do |_app|
        BlueprintConfig.after_initialize.call
      end
    end
  end
end

BlueprintConfig.env_options ||= {}

BlueprintConfig.before_initialize ||= proc do
  require 'blueprint_config/backend/credentials'
  require 'blueprint_config/backend/active_record'

  BlueprintConfig.instance.init do |backends|
    backends.use :app,         BlueprintConfig::Backend::YAML.new('config/app.yml')
    backends.use :credentials, BlueprintConfig::Backend::Credentials.new
    backends.use :env,         BlueprintConfig::Backend::ENV.new(BlueprintConfig.env_options)
    backends.use :app_local,   BlueprintConfig::Backend::YAML.new('config/app.local.yml')
  end
end

BlueprintConfig.after_initialize ||= proc do
  BlueprintConfig.instance.refine do |backends|
    if backends[:env]
      backends.insert_after :env, :db, BlueprintConfig::Backend::ActiveRecord.new
    else
      backends.push :db, BlueprintConfig::Backend::ActiveRecord.new
    end
  end
end
