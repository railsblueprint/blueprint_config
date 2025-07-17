# frozen_string_literal: true

require 'blueprint_config/backend/memory'

describe BlueprintConfig::Backend::Memory do
  let(:backend) { described_class.new }

  describe '#load_keys' do
    it 'returns empty hash initially' do
      expect(backend.load_keys).to eq({})
    end

    it 'returns stored values as nested structure' do
      backend.set('foo', 'bar')
      expect(backend.load_keys).to eq({ foo: 'bar' })
    end

    it 'returns a copy of the store' do
      backend.set('foo', 'bar')
      loaded = backend.load_keys
      loaded[:baz] = 'qux'
      expect(backend.load_keys).to eq({ foo: 'bar' })
    end
  end

  describe '#set' do
    context 'with simple key-value' do
      it 'stores the value' do
        backend.set('foo', 'bar')
        expect(backend.load_keys[:foo]).to eq('bar')
      end

      it 'converts key to string' do
        backend.set(:foo, 'bar')
        expect(backend.load_keys[:foo]).to eq('bar')
      end

      it 'overwrites existing value' do
        backend.set('foo', 'bar')
        backend.set('foo', 'baz')
        expect(backend.load_keys[:foo]).to eq('baz')
      end

      it 'handles numeric values' do
        backend.set('port', 3000)
        expect(backend.load_keys[:port]).to eq(3000)
      end

      it 'handles boolean values' do
        backend.set('enabled', true)
        expect(backend.load_keys[:enabled]).to be true
      end

      it 'handles nil values' do
        backend.set('empty', nil)
        expect(backend.load_keys[:empty]).to be nil
      end
    end

    context 'with nested hash value' do
      it 'creates nested structure from single level hash' do
        backend.set('smtp', { server: 'localhost', port: 1025 })
        expect(backend.load_keys).to eq({
          smtp: {
            server: 'localhost',
            port: 1025
          }
        })
      end

      it 'creates nested structure from deeply nested hash' do
        backend.set('app', {
          mail: {
            smtp: {
              settings: {
                address: '127.0.0.1',
                port: 587
              }
            }
          }
        })
        expect(backend.load_keys).to eq({
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
        })
      end

      it 'handles empty parent key' do
        backend.set('', { foo: 'bar', baz: 'qux' })
        expect(backend.load_keys).to eq({
          foo: 'bar',
          baz: 'qux'
        })
      end

      it 'merges with existing values' do
        backend.set('app.name', 'MyApp')
        backend.set('app', { version: '1.0' })
        expect(backend.load_keys).to include(
          app: {
            name: 'MyApp',
            version: '1.0'
          }
        )
      end

      it 'handles mixed types in nested hash' do
        backend.set('config', {
          string: 'value',
          number: 42,
          boolean: true,
          null: nil,
          nested: { key: 'value' }
        })
        
        expect(backend.load_keys).to eq({
          config: {
            string: 'value',
            number: 42,
            boolean: true,
            null: nil,
            nested: {
              key: 'value'
            }
          }
        })
      end
    end

    context 'with dotted keys' do
      it 'creates nested structure from dotted keys' do
        backend.set('smtp.server', 'mail.example.com')
        backend.set('smtp.port', 587)
        expect(backend.load_keys).to eq({
          smtp: {
            server: 'mail.example.com',
            port: 587
          }
        })
      end
    end
  end

  describe '#clear' do
    it 'removes all stored values' do
      backend.set('foo', 'bar')
      backend.set('baz', 'qux')
      backend.clear
      expect(backend.load_keys).to eq({})
    end

    it 'allows setting new values after clear' do
      backend.set('foo', 'bar')
      backend.clear
      backend.set('new', 'value')
      expect(backend.load_keys).to eq({ new: 'value' })
    end
  end

  describe '#fresh?' do
    it 'always returns true' do
      expect(backend.fresh?).to be true
      backend.set('foo', 'bar')
      expect(backend.fresh?).to be true
    end
  end

  describe '#source' do
    it 'returns the class name' do
      expect(backend.source).to eq('BlueprintConfig::Backend::Memory')
    end
  end
end