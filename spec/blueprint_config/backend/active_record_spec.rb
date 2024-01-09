# frozen_string_literal: true

require 'active_record'
require 'blueprint_config/backend/active_record'

describe BlueprintConfig::Backend::ActiveRecord do
  let(:options) { {} }
  let(:subject) { described_class.new(options).load_keys }

  context 'Database is correctly setup' do
    around do |example|
      ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

      ActiveRecord::Base.connection.create_table :settings do |t|
        t.string :key, null: false, index: { unique: true }
        t.integer :type, null: false, default: 0
        t.string :value
        t.timestamps
      end

      BlueprintConfig::Setting.create(key: 'foo', type: :string, value: 'bar')
      BlueprintConfig::Setting.create(key: 'x', type: :integer, value: '1')
      BlueprintConfig::Setting.create(key: 'a.b', type: :string, value: '1')

      example.run
      ActiveRecord::Base.remove_connection
    end

    context 'with default options' do
      it 'loads all keys' do
        expect(subject).to eq({ foo: 'bar', "a.b": '1', x: 1 })
      end
    end

    context 'when nesting enabled' do
      let(:options) { { nest: true } }
      it 'loads all keys' do
        expect(subject).to eq({ foo: 'bar', a: { b: '1' }, x: 1 })
      end
    end
  end

  context 'Database is not configured' do
    it 'returns empty hash' do
      expect(subject).to eq({})
    end
  end

  context 'Database does not have proper table' do
    around do |example|
      ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

      example.run
      ActiveRecord::Base.remove_connection
    end

    it 'returns empty hash' do
      expect(subject).to eq({})
    end
    it 'prints warning in console' do
      expect { subject }.to output(a_string_including('blueprint_config:install'))
        .to_stdout_from_any_process
    end
    context 'when silencing enabled' do
      let(:options) { { silence_warnings: true } }
      it 'prints nothing in console' do
        expect { subject }.to_not output.to_stdout_from_any_process
      end
    end
  end

  context 'Database does table does not have correct attributes' do
    around do |example|
      ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
      ActiveRecord::Base.connection.create_table :settings do |t|
        t.string :alias, null: false, index: { unique: true }
        t.integer :type, null: false, default: 0
        t.string :string
      end
      BlueprintConfig::Setting.reset_column_information
      BlueprintConfig::Setting.create(alias: 'foo', type: :string, string: 'bar')
      BlueprintConfig::Setting.create(alias: 'x', type: :integer, string: '1')
      BlueprintConfig::Setting.create(alias: 'a.b', type: :integer, string: '1')

      example.run
      ActiveRecord::Base.remove_connection
    end

    it 'returns empty hash' do
      expect(subject).to eq({})
    end
    it 'prints warning in console' do
      expect { subject }.to output(a_string_including('blueprint_config:install'))
        .to_stdout_from_any_process
    end
    context 'when silencing enabled' do
      let(:options) { { silence_warnings: true } }
      it 'prints nothing in console' do
        expect { subject }.to_not output.to_stdout_from_any_process
      end
    end
  end

  context 'Database does not have any records' do
    around do |example|
      ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
      ActiveRecord::Base.connection.create_table :settings do |t|
        t.string :key, null: false, index: { unique: true }
        t.integer :type, null: false, default: 0
        t.string :value
        t.timestamps
      end
      example.run
      ActiveRecord::Base.remove_connection
    end

    it 'returns empty hash' do
      expect(subject).to eq({})
    end
  end
end
