# frozen_string_literal: true

require 'blueprint_config/backend/base'

module BlueprintConfig
  module Backend
    class ENV < Base
      attr_accessor :options

      def initialize(options = {})
        @options = options
      end

      def load_keys
        {
          # env: ::ENV.to_h.transform_keys(&:to_sym),
          ** transformed_env
        }
      end

      def env_downcased
        @env_downcased ||= ::ENV.to_h.transform_keys(&:downcase)
      end

      def env_downcased_keys
        @env_downcased_keys ||= env_downcased.keys
      end

      def filtered_env
        return env_downcased if @options[:allow_all]

        allowed_keys = @options[:whitelist_keys]&.map(&:to_s) || []
        @options[:whitelist_prefixes]&.each do |prefix|
          allowed_keys += env_downcased_keys.select { |key| key.to_s.start_with?(prefix.to_s) }
        end

        env_downcased.slice(* allowed_keys)
      end

      def transformed_env
        return filtered_env.transform_keys(&:to_sym) unless @options[:nest]

        nest_hash(filtered_env, @options[:nest_separator] || '_')
      end
    end
  end
end
