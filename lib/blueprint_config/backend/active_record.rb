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

        rails generate blue_config:migration
        rake db:migrate
        =======================================================================
      WARNING

      def initialize(options = {})
        @options = options
        @updated_at = nil
        @last_checked_at = nil
        @mutex = Mutex.new
      end

      def load_keys
        update_timestamp

        data = Setting.all.map { |s| { s.key => s.parsed_value } }.reduce(:merge) || {}
        return data.transform_keys(&:to_sym) unless @options[:nest]

        nest_hash(data, @options[:nest_separator] || '.')
      end

      def update_timestamp
        @mutex.synchronize do
          @updated_at = Setting.maximum(:updated_at)
        end
      end

      def fresh?
        return true if @last_checked_at.present? && @last_checked_at > 1.second.ago

        @mutex.synchronize do
          @last_checked_at = Time.now
        end
        @updated_at.present? && @updated_at >= Setting.maximum(:updated_at)
      end
    end
  end
end
