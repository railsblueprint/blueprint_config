# frozen_string_literal: true

require 'erb'
require 'yaml'
require 'active_support/hash_with_indifferent_access'

module BlueprintConfig
  module Backend
    class YAML < Base
      def initialize(path = 'config/app.yml')
        @path = path
      end

      def load_keys
        if File.exist?(path)
          parsed = ::YAML.load(File.read(path), aliases: true).deep_symbolize_keys
          parsed.fetch(:default, {}).deep_merge(parsed.fetch(BlueprintConfig.env&.to_sym, {}))
        else
          {}
        end
      end

      private

      def path
        File.expand_path(@path, BlueprintConfig.root)
      end
    end
  end
end
