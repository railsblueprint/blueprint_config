# frozen_string_literal: true

require 'spec_helper'
require 'blueprint_config/options_hash'
require 'blueprint_config/options_array'

describe BlueprintConfig::OptionsHash do
  describe '#with_sources' do
    describe 'simple values' do
    it 'returns hash with value and source for each key' do
      hash = BlueprintConfig::OptionsHash.new(
        { foo: 'bar', num: 42 },
        source: 'TestBackend'
      )

      result = hash.with_sources
      expect(result).to eq({
        foo: { value: 'bar', source: 'TestBackend' },
        num: { value: 42, source: 'TestBackend' }
      })
    end
  end

  describe 'nested hashes' do
    it 'recursively includes sources for nested values' do
      hash = BlueprintConfig::OptionsHash.new(
        {
          smtp: {
            server: 'localhost',
            port: 1025
          },
          features: {
            enabled: true
          }
        },
        source: 'ConfigFile'
      )

      result = hash.with_sources
      expect(result[:smtp][:server]).to eq({ value: 'localhost', source: 'ConfigFile' })
      expect(result[:smtp][:port]).to eq({ value: 1025, source: 'ConfigFile' })
      expect(result[:features][:enabled]).to eq({ value: true, source: 'ConfigFile' })
    end
  end

  describe 'arrays' do
    it 'handles arrays properly' do
      hash = BlueprintConfig::OptionsHash.new(
        {
          servers: ['web1', 'web2', 'web3'],
          ports: [80, 443]
        },
        source: 'YAMLBackend'
      )

      result = hash.with_sources
      expect(result[:servers]).to eq({
        value: ['web1', 'web2', 'web3'],
        source: 'YAMLBackend'
      })
      expect(result[:ports]).to eq({
        value: [80, 443],
        source: 'YAMLBackend'
      })
    end
  end

  describe 'mixed sources after merge' do
    it 'preserves individual sources after deep merge' do
      # First configuration from YAML
      yaml_config = BlueprintConfig::OptionsHash.new(
        {
          smtp: { server: 'smtp.example.com', port: 587 },
          app: { name: 'MyApp' }
        },
        source: 'YAML'
      )

      # Override some values from credentials
      creds_config = BlueprintConfig::OptionsHash.new(
        {
          smtp: { username: 'user@example.com' },
          database: { password: 'secret' }
        },
        source: 'Credentials'
      )

      # Merge configurations
      yaml_config.deep_merge!(creds_config)

      result = yaml_config.with_sources
      
      # Original YAML values
      expect(result[:smtp][:server]).to eq({ value: 'smtp.example.com', source: 'YAML' })
      expect(result[:smtp][:port]).to eq({ value: 587, source: 'YAML' })
      expect(result[:app][:name]).to eq({ value: 'MyApp', source: 'YAML' })
      
      # Values from credentials
      expect(result[:smtp][:username]).to eq({ value: 'user@example.com', source: 'Credentials' })
      expect(result[:database][:password]).to eq({ value: 'secret', source: 'Credentials' })
    end
  end

  describe 'deeply nested structures' do
    it 'handles deeply nested structures' do
      hash = BlueprintConfig::OptionsHash.new(
        {
          level1: {
            level2: {
              level3: {
                value: 'deep',
                array: [1, 2, 3]
              }
            }
          }
        },
        source: 'DeepSource'
      )

      result = hash.with_sources
      expect(result[:level1][:level2][:level3][:value]).to eq({
        value: 'deep',
        source: 'DeepSource'
      })
      expect(result[:level1][:level2][:level3][:array]).to eq({
        value: [1, 2, 3],
        source: 'DeepSource'
      })
    end
  end
  end
end