# frozen_string_literal: true

require 'active_support/encrypted_configuration'

module BlueprintConfig
  module Backend
    class Credentials < Base
      def load_keys
        if defined?(Rails)
          # When Rails is available, use Rails.application.credentials
          # Rails already handles merging global and environment-specific credentials
          Rails.application.credentials.to_h
        else
          # Standalone mode - just load global credentials
          standalone_credentials.to_h
        end
      end

      def source
        if defined?(Rails) && Rails.env
          # Check if environment-specific credentials exist
          env_path = "config/credentials/#{Rails.env}.yml.enc"
          if File.exist?(env_path)
            "#{self.class.name}(global + #{Rails.env})"
          else
            "#{self.class.name}(global)"
          end
        else
          "#{self.class.name}"
        end
      end

      private

      def standalone_credentials
        ActiveSupport::EncryptedConfiguration.new(
          config_path: 'config/credentials.yml.enc',
          key_path: 'config/master.key',
          env_key: 'RAILS_MASTER_KEY',
          raise_if_missing_key: false
        )
      end
    end
  end
end
