# frozen_string_literal: true

require 'spec_helper'
require 'blueprint_config'
require 'blueprint_config/backend/yaml'
require 'blueprint_config/backend/credentials'
require 'blueprint_config/backend/env'
require 'blueprint_config/backend/active_record'
require 'blueprint_config/backend/memory'

describe 'Backend source tracking' do
  describe BlueprintConfig::Backend::YAML do
    let(:yaml_backend) { described_class.new('config/test.yml') }
    
    describe '#source' do
      it 'includes the file path' do
        expect(yaml_backend.source).to eq('BlueprintConfig::Backend::YAML(config/test.yml)')
      end
    end
  end

  describe BlueprintConfig::Backend::Credentials do
    let(:credentials_backend) { described_class.new }
    
    describe '#source' do
      context 'without Rails' do
        before do
          hide_const('Rails')
        end
        
        it 'returns just the class name' do
          expect(credentials_backend.source).to eq('BlueprintConfig::Backend::Credentials')
        end
      end
      
      context 'with Rails in development' do
        before do
          unless defined?(Rails)
            module Rails
              def self.env
                ActiveSupport::StringInquirer.new('development')
              end
              def self.root
                Pathname.new('/app')
              end
            end
          end
        end
        
        after do
          Object.send(:remove_const, :Rails) if defined?(Rails)
        end
        
        it 'shows environment info when no env-specific file exists' do
          allow(File).to receive(:exist?).with('config/credentials/development.yml.enc').and_return(false)
          expect(credentials_backend.source).to eq('BlueprintConfig::Backend::Credentials(global)')
        end
        
        it 'shows merged info when env-specific file exists' do
          allow(File).to receive(:exist?).with('config/credentials/development.yml.enc').and_return(true)
          expect(credentials_backend.source).to eq('BlueprintConfig::Backend::Credentials(global + development)')
        end
      end
    end
  end

  describe BlueprintConfig::Backend::ENV do
    describe '#source' do
      it 'returns class name when no options' do
        env_backend = described_class.new
        expect(env_backend.source).to eq('BlueprintConfig::Backend::ENV')
      end
      
      it 'includes whitelist_keys when configured' do
        env_backend = described_class.new(whitelist_keys: ['API_KEY', 'SECRET'])
        expect(env_backend.source).to eq('BlueprintConfig::Backend::ENV(whitelist_keys: API_KEY, SECRET)')
      end
      
      it 'includes whitelist_prefixes when configured' do
        env_backend = described_class.new(whitelist_prefixes: ['APP_', 'MYAPP_'])
        expect(env_backend.source).to eq('BlueprintConfig::Backend::ENV(whitelist_prefixes: APP_, MYAPP_)')
      end
      
      it 'includes both options when configured' do
        env_backend = described_class.new(
          whitelist_keys: ['API_KEY'],
          whitelist_prefixes: ['APP_']
        )
        expect(env_backend.source).to eq('BlueprintConfig::Backend::ENV(whitelist_keys: API_KEY, whitelist_prefixes: APP_)')
      end
    end
  end

  describe BlueprintConfig::Backend::ActiveRecord do
    let(:ar_backend) { described_class.new }
    
    describe '#source' do
      context 'when table exists' do
        before do
          allow(ar_backend).to receive(:table_exist?).and_return(true)
          ar_backend.instance_variable_set(:@configured, true)
        end
        
        it 'shows settings table' do
          expect(ar_backend.source).to eq('BlueprintConfig::Backend::ActiveRecord(settings table)')
        end
      end
      
      context 'when not configured' do
        before do
          ar_backend.instance_variable_set(:@configured, false)
        end
        
        it 'shows not available' do
          expect(ar_backend.source).to eq('BlueprintConfig::Backend::ActiveRecord(not available)')
        end
      end
    end
  end

  describe BlueprintConfig::Backend::Memory do
    let(:memory_backend) { described_class.new }
    
    describe '#source' do
      it 'returns the class name' do
        expect(memory_backend.source).to eq('BlueprintConfig::Backend::Memory')
      end
    end
  end
end