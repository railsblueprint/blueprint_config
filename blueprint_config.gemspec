# frozen_string_literal: true

require 'English'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blueprint_config/version'

Gem::Specification.new do |gem|
  gem.name          = 'blueprint_config'
  gem.version       = BlueprintConfig::VERSION
  gem.authors       = ['Vladimir Elchinov', 'Rails Blueprint']
  gem.email         = ['elik@elik.ru', 'info@railsblueprint.com']
  gem.description   = 'Flexible configuration for Ruby/Rails applications with a variety of backends'
  gem.summary       = 'Congifure Ruby apps'
  gem.homepage      = 'https://github.com/railsblueprint/blueprint_config'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '~> 3.0'

  gem.add_development_dependency 'activerecord'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'redis'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'
end
