# frozen_string_literal: true

require 'active_record'
require 'blueprint_config/backend/active_record'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

ActiveRecord::Base.connection.create_table :settings do |t|
  t.string :key, null: false, index: { unique: true }
  t.integer :type, null: false, default: 0
  t.string :value
  t.timestamps
end

describe BlueprintConfig::Backend::ActiveRecord do
  let(:options) { {} }
  let(:subject) { described_class.new(options).load_keys }
  around do |example|
    ActiveRecord::Base.transaction do
      BlueprintConfig::Setting.create(key: 'foo', type: :string, value: 'bar')
      BlueprintConfig::Setting.create(key: 'x', type: :integer, value: '1')
      BlueprintConfig::Setting.create(key: 'a.b', type: :string, value: '1')

      example.run
      raise ActiveRecord::Rollback
    end
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
