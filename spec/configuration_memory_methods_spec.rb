# frozen_string_literal: true

require 'spec_helper'
require 'blueprint_config'

describe BlueprintConfig::Configuration do
  let(:config) { BlueprintConfig::Configuration.instance }
  
  before do
    # Mock Rails test environment
    unless defined?(Rails)
      module Rails
        def self.env
          ActiveSupport::StringInquirer.new('test')
        end
        
        def self.application
          app = Object.new
          credentials = {}
          app.define_singleton_method(:credentials) { credentials }
          app
        end
      end
    end
    
    # Initialize with memory backend
    config.instance_variable_set(:@backends, nil)
    config.instance_variable_set(:@config, nil)
    BlueprintConfig.before_initialize.call
    BlueprintConfig.after_initialize.call
  end
  
  after do
    Object.send(:remove_const, :Rails) if defined?(Rails)
    config.clear_memory! if config.backends[:memory]
  end
  
  describe '#set' do
    context 'in test environment' do
      it 'sets a simple value' do
        config.set('foo', 'bar')
        expect(config[:foo]).to eq('bar')
      end
      
      it 'sets a value with dotted key' do
        config.set('smtp.server', 'test.example.com')
        expect(config.dig(:smtp, :server)).to eq('test.example.com')
      end
      
      it 'accepts hash argument to set multiple values' do
        config.set(
          foo: 'bar',
          smtp: { server: 'localhost', port: 1025 }
        )
        
        expect(config[:foo]).to eq('bar')
        expect(config.dig(:smtp, :server)).to eq('localhost')
        expect(config.dig(:smtp, :port)).to eq(1025)
      end
      
      it 'converts keys to strings' do
        config.set(:symbol_key, 'value')
        expect(config[:symbol_key]).to eq('value')
      end
      
      it 'triggers reload after setting' do
        expect(config).to receive(:reload!).at_least(:once)
        config.set('test', 'value')
      end
    end
    
    context 'without memory backend' do
      before do
        # Remove memory backend
        backends = config.backends
        memory = backends[:memory]
        backends.delete(:memory) if memory
      end
      
      it 'raises error when memory backend is not configured' do
        expect { config.set('foo', 'bar') }.to raise_error(/Memory backend not configured/)
      end
    end
  end
  
  describe '#clear_memory!' do
    context 'with memory backend' do
      before do
        config.set('foo', 'bar')
        config.set('nested.key', 'value')
      end
      
      it 'clears all memory-stored values' do
        expect(config[:foo]).to eq('bar')
        config.clear_memory!
        expect { config.fetch(:foo) }.to raise_error(KeyError)
      end
      
      it 'triggers reload after clearing' do
        expect(config).to receive(:reload!).at_least(:once)
        config.clear_memory!
      end
      
      it 'allows setting new values after clear' do
        config.clear_memory!
        config.set('new', 'value')
        expect(config[:new]).to eq('value')
      end
    end
    
    context 'without memory backend' do
      before do
        # Remove memory backend
        backends = config.backends
        memory = backends[:memory]
        backends.delete(:memory) if memory
      end
      
      it 'does nothing when memory backend is not present' do
        expect { config.clear_memory! }.not_to raise_error
      end
    end
  end
  
  describe 'non-test environment behavior' do
    before do
      # Mock production environment
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      
      # Reinitialize without memory backend
      config.instance_variable_set(:@backends, nil)
      config.instance_variable_set(:@config, nil)
      BlueprintConfig.before_initialize.call
      BlueprintConfig.after_initialize.call
    end
    
    it 'does not include memory backend in production' do
      expect(config.backends[:memory]).to be_nil
    end
    
    it 'raises error when trying to set in production' do
      expect { config.set('foo', 'bar') }.to raise_error(/Memory backend not configured/)
    end
  end
end