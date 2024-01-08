# frozen_string_literal: true

require 'active_record'
require 'blueprint_config/backend/base'
require 'blueprint_config/setting'

module BlueprintConfig
  module Backend
    class ActiveRecord < Base
      MISSING_TABLE_WARNING = <<-WARNING.gsub(/^ */, '')
        =======================================================================
        Settings table not found. Please add the configuration table by running:

        rails generate blueprint_config:install
        rake db:migrate
        =======================================================================
      WARNING

      def initialize(options = {})
        @options = options
        @updated_at = nil
        @last_checked_at = nil
        @configured = true
        @mutex = Thread::Mutex.new
      end

      def load_keys
        @configured = true
        update_timestamp

        data = Setting.all.map { |s| { s.key => s.parsed_value } }.reduce(:merge) || {}
        return data.transform_keys(&:to_sym) unless @options[:nest]

        nest_hash(data, @options[:nest_separator] || '.')
      rescue ::ActiveRecord::NoDatabaseError => e
        # database is not created yet
        @configured = false
        {}
      rescue ::ActiveRecord::StatementInvalid => e
        @configured = false
        Rails.logger.warn(e.message)
        Rails.logger.warn(MISSING_TABLE_WARNING)
        {}
      end

      def update_timestamp
        @mutex.synchronize do
          @updated_at = Setting.maximum(:updated_at)
        end
      end

      def fresh?
        # if database is not create/configured yet - don't try to refresh settings from it
        return true unless @configured
        return true if @last_checked_at.present? && @last_checked_at > 1.second.ago

        @mutex.synchronize do
          @last_checked_at = Time.now
        end
        max_updated_at = Setting.maximum(:updated_at)

        # if there is no settings in the database - don't try to refresh settings from it'
        return true if max_updated_at.blank?

        @updated_at.present? && @updated_at >= max_updated_at
      end
    end
  end
end
