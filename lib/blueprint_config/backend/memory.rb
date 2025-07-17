# frozen_string_literal: true

module BlueprintConfig
  module Backend
    class Memory < Base
      def initialize
        super
        @store = {}
      end

      def load_keys
        # Return the flattened store which will be nested by BlueprintConfig
        nest_hash(@store, '.')
      end

      def set(key, value)
        if value.is_a?(Hash)
          # Handle nested hashes - store them properly for nested access
          nested_hash = flatten_hash(value, key.to_s)
          @store.merge!(nested_hash)
        else
          @store[key.to_s] = value
        end
      end

      def clear
        @store.clear
      end

      def fresh?
        true
      end

      private

      def flatten_hash(hash, parent_key = '')
        result = {}
        hash.each do |k, v|
          new_key = parent_key.empty? ? k.to_s : "#{parent_key}.#{k}"
          if v.is_a?(Hash)
            result.merge!(flatten_hash(v, new_key))
          else
            result[new_key] = v
          end
        end
        result
      end
    end
  end
end