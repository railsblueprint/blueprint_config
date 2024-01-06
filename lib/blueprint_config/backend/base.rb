# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'

module BlueprintConfig
  module Backend
    class Base
      def nest_hash(hash, delimiter = '_')
        hash.each_with_object({}) do |(key, value), results|
          steps = key.split(delimiter).reverse
          nested = steps.reduce(value) { |value, key| { key.to_sym => value } }

          results.deep_merge!(nested) do |_key, a, b|
            if a.is_a?(Hash) && b.is_a?(String)
              a.deep_merge(nil => b)
            elsif b.is_a?(Hash) && a.is_a?(String)
              b.deep_merge(nil => a)
            else
              b
            end
          end
        end
      end

      def source
        self.class.name
      end

      def fresh?
        true
      end
    end
  end
end
