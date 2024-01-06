# frozen_string_literal: true

require 'active_support/encrypted_configuration'

module BlueprintConfig
  module Backend
    class Credentials < Base
      def load_keys
        credentials.to_h
      end

      def credentials
        if defined?(Rails)
          Rails.application.credentials
        else
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
end
