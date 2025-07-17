# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_support/string_inquirer'
require 'blueprint_config'

BlueprintConfig.root = File.dirname(__FILE__)
BlueprintConfig.env = 'test'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = %i[expect should]
  end

  config.mock_with :rspec do |c|
    c.syntax = %i[expect should]
  end
end
