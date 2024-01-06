# frozen_string_literal: true

describe BlueprintConfig::Configuration do
  let(:key_set1) do
    {
      a: 1,
      b: 2
    }
  end

  let(:key_set2) do
    {
      a: 3,
      c: 4,
      e: '<%= AppConfig.a %>'
    }
  end

  let(:backend) { double('backend', load_keys: key_set1, source: 'backend', fresh?: true) }
  let(:other_backend) { double('other backend', load_keys: key_set2, source: 'other_backend', fresh?: true) }
  let(:config) { described_class.instance }

  before do
    stub_const('AppConfig', config)
    config.init do |backends|
      backends.push(:one, backend)
      backends.push(:other, other_backend)
    end
  end

  describe 'getting values as method calls' do
    it 'returns the value of a given key' do
      expect(config.a).to eq(3)
      expect(config.c).to eq(4)
      expect(config.e).to eq('3')
    end
    it 'checks backend freshness' do
      expect(backend).to receive(:fresh?).and_return(true)
      expect(config.c).to eq(4)
    end
    it 'reloads when backend is stale' do
      expect(backend).to receive(:fresh?).and_return(false)
      expect(config).to receive(:reload!).and_call_original
      expect(config.c).to eq(4)
    end
  end

  describe 'getting values with []' do
    it 'returns the value of a given key' do
      expect(config[:a]).to eq(3)
      expect(config[:c]).to eq(4)
      expect(config[:e]).to eq('3')
    end
    it 'checks backend freshness' do
      expect(backend).to receive(:fresh?).and_return(true)
      expect(config[:c]).to eq(4)
    end
    it 'reloads when backend is stale' do
      expect(backend).to receive(:fresh?).and_return(false)
      expect(config).to receive(:reload!).and_call_original
      expect(config[:c]).to eq(4)
    end
  end

  describe 'getting values with dig' do
    it 'returns the value of a given key' do
      expect(config[:a]).to eq(3)
      expect(config[:c]).to eq(4)
      expect(config[:e]).to eq('3')
    end
    it 'checks backend freshness' do
      expect(backend).to receive(:fresh?).and_return(true)
      expect(config[:c]).to eq(4)
    end
    it 'reloads when backend is stale' do
      expect(backend).to receive(:fresh?).and_return(false)
      expect(config).to receive(:reload!).and_call_original
      expect(config[:c]).to eq(4)
    end
  end

  describe 'getting values with dig!' do
    it 'returns the value of a given key' do
      expect(config.dig!(:a)).to eq(3)
      expect(config.dig!(:c)).to eq(4)
      expect(config.dig!(:e)).to eq('3')
    end
    it 'checks backend freshness' do
      expect(backend).to receive(:fresh?).and_return(true)
      expect(config.dig!(:c)).to eq(4)
    end
    it 'reloads when backend is stale' do
      expect(backend).to receive(:fresh?).and_return(false)
      expect(config).to receive(:reload!).and_call_original
      expect(config.dig!(:c)).to eq(4)
    end
  end
end
