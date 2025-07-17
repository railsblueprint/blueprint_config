# frozen_string_literal: true

require 'spec_helper'
require 'blueprint_config'
require 'tmpdir'
require 'fileutils'

describe 'Configuration integration with all features' do
  let(:temp_dir) { Dir.mktmpdir }
  let(:app_yml_path) { File.join(temp_dir, 'config', 'app.yml') }
  let(:app_local_yml_path) { File.join(temp_dir, 'config', 'app.local.yml') }
  
  before do
    # Setup directory structure
    FileUtils.mkdir_p(File.join(temp_dir, 'config'))
    
    # Mock BlueprintConfig root
    allow(BlueprintConfig).to receive(:root).and_return(temp_dir)
    allow(BlueprintConfig).to receive(:env).and_return('test')
    
    # Create YAML files
    File.write(app_yml_path, <<~YAML)
      default:
        app:
          name: MyApp
          version: 1.0
        smtp:
          server: smtp.example.com
          port: 587
      test:
        app:
          name: MyApp Test
        smtp:
          port: 1025
    YAML
    
    File.write(app_local_yml_path, <<~YAML)
      default:
        debug:
          verbose: true
        smtp:
          server: localhost
    YAML
    
    # Mock Rails for credentials
    unless defined?(Rails)
      module Rails
        def self.env
          ActiveSupport::StringInquirer.new('test')
        end
        def self.application
          Struct.new(:credentials).new(
            OpenStruct.new(
              database: { password: 'secret123' },
              api: { token: 'api_key_123' }
            )
          )
        end
      end
    end
    
    # Set some ENV variables
    ENV['APP_HOST'] = 'test.example.com'
    ENV['APP_FEATURE_NEW_UI'] = 'true'
    
    # Initialize configuration
    BlueprintConfig.instance.instance_variable_set(:@backends, nil)
    BlueprintConfig.instance.instance_variable_set(:@config, nil)
    BlueprintConfig.before_initialize.call
    BlueprintConfig.after_initialize.call
    BlueprintConfig.define_shortcut
  end
  
  after do
    FileUtils.rm_rf(temp_dir)
    ENV.delete('APP_HOST')
    ENV.delete('APP_FEATURE_NEW_UI')
    
    # Clean up memory backend
    if defined?(AppConfig) && AppConfig.respond_to?(:clear_memory!)
      AppConfig.clear_memory!
    end
    
    Object.send(:remove_const, :Rails) if defined?(Rails)
    Object.send(:remove_const, :AppConfig) if defined?(AppConfig)
  end
  
  describe 'configuration loading and precedence' do
    it 'loads values from all backends' do
      # From app.yml default section
      expect(AppConfig.app.version).to eq(1.0)
      
      # From app.yml test section (overrides default)
      expect(AppConfig.app.name).to eq('MyApp Test')
      
      # From credentials
      expect(AppConfig.database.password).to eq('secret123')
      expect(AppConfig.api.token).to eq('api_key_123')
      
      # From app.local.yml (highest file priority)
      expect(AppConfig.debug.verbose).to be true
      expect(AppConfig.smtp.server).to eq('localhost')
    end
    
    it 'respects configuration precedence' do
      # app.yml sets port to 587, test section overrides to 1025
      expect(AppConfig.smtp.port).to eq(1025)
      
      # app.local.yml overrides server from app.yml
      expect(AppConfig.smtp.server).to eq('localhost')
    end
  end
  
  describe 'memory backend in test environment' do
    it 'allows setting values that override all other sources' do
      # Original value from app.local.yml
      expect(AppConfig.smtp.server).to eq('localhost')
      
      # Override with memory backend
      AppConfig.set('smtp.server', 'memory.example.com')
      expect(AppConfig.smtp.server).to eq('memory.example.com')
      
      # Clear memory
      AppConfig.clear_memory!
      expect(AppConfig.smtp.server).to eq('localhost')
    end
    
    it 'supports setting nested values with hash' do
      AppConfig.set(
        features: {
          new_ui: true,
          beta: false,
          limits: {
            max_users: 100,
            max_projects: 10
          }
        }
      )
      
      expect(AppConfig.features.new_ui).to be true
      expect(AppConfig.features.beta).to be false
      expect(AppConfig.features.limits.max_users).to eq(100)
      expect(AppConfig.features.limits.max_projects).to eq(10)
    end
  end
  
  describe 'source tracking' do
    it 'tracks sources for values from different backends' do
      expect(AppConfig.config.source(:app, :name)).to include('YAML(config/app.yml)')
      expect(AppConfig.config.source(:database, :password)).to include('Credentials')
      expect(AppConfig.config.source(:debug, :verbose)).to include('YAML(config/app.local.yml)')
    end
    
    it 'shows memory backend source when value is overridden' do
      AppConfig.set('test.value', 'from memory')
      expect(AppConfig.config.source(:test, :value)).to include('Memory')
    end
  end
  
  describe 'with_sources method' do
    it 'returns all values with their sources' do
      result = AppConfig.config.with_sources
      
      # Check structure
      expect(result).to be_a(Hash)
      expect(result[:app][:name]).to be_a(Hash)
      expect(result[:app][:name]).to have_key(:value)
      expect(result[:app][:name]).to have_key(:source)
      
      # Check values and sources
      expect(result[:app][:name][:value]).to eq('MyApp Test')
      expect(result[:app][:name][:source]).to include('YAML')
      
      expect(result[:database][:password][:value]).to eq('secret123')
      expect(result[:database][:password][:source]).to include('Credentials')
    end
    
    it 'includes memory backend sources' do
      AppConfig.set('dynamic.setting', 'test value')
      result = AppConfig.config.with_sources
      
      expect(result[:dynamic][:setting][:value]).to eq('test value')
      expect(result[:dynamic][:setting][:source]).to include('Memory')
    end
  end
  
  describe 'configuration access methods' do
    it 'supports member access syntax' do
      expect(AppConfig.app.name).to eq('MyApp Test')
    end
    
    it 'supports hash access syntax' do
      expect(AppConfig[:app][:name]).to eq('MyApp Test')
      expect(AppConfig['app']['name']).to eq('MyApp Test')
    end
    
    it 'supports dig method' do
      expect(AppConfig.dig(:app, :name)).to eq('MyApp Test')
      expect(AppConfig.dig(:non, :existent)).to be_nil
    end
    
    it 'supports bang methods for missing keys' do
      expect { AppConfig.missing! }.to raise_error(KeyError, /missing/)
    end
    
    it 'supports question methods for checking existence' do
      expect(AppConfig.app?).to be true
      expect(AppConfig.missing?).to be false
    end
  end

  describe 'convenience methods' do
    it 'supports AppConfig.to_h' do
      result = AppConfig.to_h
      expect(result).to be_a(Hash)
      expect(result[:app][:name]).to eq('MyApp Test')
      expect(result[:database][:password]).to eq('secret123')
    end

    it 'supports AppConfig.with_sources' do
      result = AppConfig.with_sources
      expect(result).to be_a(Hash)
      expect(result[:app][:name]).to have_key(:value)
      expect(result[:app][:name]).to have_key(:source)
      expect(result[:app][:name][:value]).to eq('MyApp Test')
      expect(result[:app][:name][:source]).to include('YAML')
    end
  end
  
  describe 'backend listing' do
    it 'can list all loaded backends' do
      backends = []
      AppConfig.backends.each { |b| backends << b.class.name }
      
      expect(backends).to include('BlueprintConfig::Backend::YAML')
      expect(backends).to include('BlueprintConfig::Backend::Credentials')
      expect(backends).to include('BlueprintConfig::Backend::Memory')
    end
    
    it 'can access specific backends' do
      expect(AppConfig.backends[:memory]).to be_a(BlueprintConfig::Backend::Memory)
      expect(AppConfig.backends[:app]).to be_a(BlueprintConfig::Backend::YAML)
      expect(AppConfig.backends[:credentials]).to be_a(BlueprintConfig::Backend::Credentials)
    end
  end
end