# frozen_string_literal: true

require 'active_record'

module BlueprintConfig
  class Setting < ::ActiveRecord::Base
    self.inheritance_column = nil

    enum :type, { section: 0, string: 1, integer: 2, boolean: 3, json: 4, selection: 5, set: 6 }

    def parsed_json_value
      parsed = begin
        JSON.parse(value)
      rescue StandardError
        nil
      end
      parsed.is_a?(Hash) ? parsed.with_indifferent_access : parsed
    end

    def parsed_value
      return value.to_i if integer?
      return value.to_b if boolean?
      return parsed_json_value if json? || set?

      value
    end
  end
end
