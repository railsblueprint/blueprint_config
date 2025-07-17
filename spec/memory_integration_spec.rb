# frozen_string_literal: true

require 'spec_helper'
require 'blueprint_config'

describe 'Memory backend integration' do
  # Simulate Rails test environment
  before(:all) do
    unless defined?(Rails)
      module Rails
        def self.env
          ActiveSupport::StringInquirer.new('test')
        end
        
        def self.application
          # Mock credentials
          app = Object.new
          credentials = {}
          app.define_singleton_method(:credentials) { credentials }
          app
        end
      end
    end
  end

  before do
    # Reset configuration
    BlueprintConfig.instance.instance_variable_set(:@backends, nil)
    BlueprintConfig.instance.instance_variable_set(:@config, nil)
    
    # Initialize with memory backend
    BlueprintConfig.before_initialize.call
    BlueprintConfig.after_initialize.call
  end

  after do
    # Clean up memory after each test
    BlueprintConfig.instance.clear_memory! if BlueprintConfig.instance.backends[:memory]
  end

  describe 'AppConfig.set' do
    before do
      BlueprintConfig.define_shortcut
    end

    context 'with simple values' do
      it 'sets and retrieves string value' do
        AppConfig.set('some.setting', 'value')
        expect(AppConfig.some.setting).to eq('value')
      end

      it 'sets and retrieves numeric value' do
        AppConfig.set('limit', 100)
        expect(AppConfig.limit).to eq(100)
      end

      it 'sets and retrieves boolean value' do
        AppConfig.set('enabled', true)
        expect(AppConfig.enabled).to be true
      end

      it 'overwrites existing values' do
        AppConfig.set('foo', 'bar')
        AppConfig.set('foo', 'baz')
        expect(AppConfig.foo).to eq('baz')
      end
    end

    context 'with hash argument' do
      it 'sets multiple values at once' do
        AppConfig.set(
          foo: 'bar',
          baz: 'qux',
          num: 42
        )
        expect(AppConfig.foo).to eq('bar')
        expect(AppConfig.baz).to eq('qux')
        expect(AppConfig.num).to eq(42)
      end

      it 'sets nested values' do
        AppConfig.set(
          smtp: {
            server: 'localhost',
            port: 1025
          }
        )
        expect(AppConfig.smtp.server).to eq('localhost')
        expect(AppConfig.smtp.port).to eq(1025)
      end

      it 'sets deeply nested values' do
        AppConfig.set(
          app: {
            mail: {
              smtp: {
                settings: {
                  address: '127.0.0.1',
                  port: 587
                }
              }
            }
          }
        )
        expect(AppConfig.app.mail.smtp.settings.address).to eq('127.0.0.1')
        expect(AppConfig.app.mail.smtp.settings.port).to eq(587)
      end
    end

    context 'with dotted key and hash value' do
      it 'combines key prefix with hash keys' do
        AppConfig.set('mail.smtp', { server: 'localhost', port: 1025 })
        expect(AppConfig.mail.smtp.server).to eq('localhost')
        expect(AppConfig.mail.smtp.port).to eq(1025)
      end
    end

    context 'memory backend priority' do
      it 'overrides values from other backends' do
        # Assuming there might be some default config
        AppConfig.set('host', 'test.example.com')
        expect(AppConfig.host).to eq('test.example.com')
      end
    end
  end

  describe 'AppConfig.clear_memory!' do
    before do
      BlueprintConfig.define_shortcut
    end

    it 'clears all memory-stored values' do
      AppConfig.set('foo', 'bar')
      AppConfig.set('baz', 'qux')
      
      AppConfig.clear_memory!
      
      # Values should revert to what's in other backends or nil
      expect { AppConfig.foo! }.to raise_error(KeyError)
      expect { AppConfig.baz! }.to raise_error(KeyError)
    end

    it 'can be used between test examples' do
      AppConfig.set('test.value', 'first')
      expect(AppConfig.test.value).to eq('first')
      
      AppConfig.clear_memory!
      
      AppConfig.set('test.value', 'second')
      expect(AppConfig.test.value).to eq('second')
    end
  end

  describe 'RSpec usage pattern' do
    before do
      BlueprintConfig.define_shortcut
    end

    context 'with some setting' do
      before do
        AppConfig.set('some.setting', 'value')
      end

      after do
        AppConfig.clear_memory!
      end

      it 'works as expected' do
        expect(AppConfig.some.setting).to eq('value')
      end

      it 'is isolated from other tests' do
        expect(AppConfig.some.setting).to eq('value')
      end
    end

    context 'with different setting' do
      before do
        AppConfig.set('some.setting', 'different')
      end

      after do
        AppConfig.clear_memory!
      end

      it 'has its own value' do
        expect(AppConfig.some.setting).to eq('different')
      end
    end
  end
end