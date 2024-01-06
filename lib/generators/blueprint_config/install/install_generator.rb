# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module BlueprintConfig
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    TEMPLATES = File.join(File.dirname(__FILE__), 'templates')
    source_paths << TEMPLATES

    def create_migration_file
      migration_template 'migration.rb.erb', 'db/migrate/create_blueprint_settings.rb'
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::STRING.to_f}]"
    end
  end
end
