# frozen_string_literal: true

require 'blueprint_config/version'
require 'blueprint_config/backend/env'
require 'blueprint_config/backend/yaml'
require 'blueprint_config/backend/memory'
require 'blueprint_config/configuration'
require 'blueprint_config/backend_collection'

module BlueprintConfig
  class << self
    attr_accessor :root, :env, :before_initialize, :after_initialize
    attr_writer :shortcut_name, :env_backend_options, :active_record_backend_options

    def shortcut_name
      @shortcut_name || 'AppConfig'
    end

    def env_backend_options
      @env_backend_options ||= {}
    end

    def active_record_backend_options
      @active_record_backend_options ||= { nest: true }
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

BlueprintConfig.before_initialize ||= proc do
  require 'blueprint_config/backend/credentials'
  require 'blueprint_config/backend/active_record'

  BlueprintConfig.instance.init do |backends|
    backends.use :app,         BlueprintConfig::Backend::YAML.new('config/app.yml')
    backends.use :credentials, BlueprintConfig::Backend::Credentials.new
    backends.use :env,         BlueprintConfig::Backend::ENV.new(BlueprintConfig.env_backend_options)
    backends.use :app_local,   BlueprintConfig::Backend::YAML.new('config/app.local.yml')
    
    # Memory backend with highest priority for test environment (added last)
    if defined?(Rails) && Rails.env.test?
      backends.use :memory, BlueprintConfig::Backend::Memory.new
    end
  end
end

BlueprintConfig.after_initialize ||= proc do
  BlueprintConfig.instance.refine do |backends|
    ar_backend = BlueprintConfig::Backend::ActiveRecord.new(BlueprintConfig.active_record_backend_options)

    if backends[:env]
      backends.insert_after :env, :db, ar_backend
    else
      backends.push :db, ar_backend
    end

    # Ensure memory backend is always last (highest priority) in test environment
    if defined?(Rails) && Rails.env.test? && backends[:memory]
      memory_backend = backends[:memory]
      backends.delete(:memory)
      backends.push :memory, memory_backend
    end
  end
end
