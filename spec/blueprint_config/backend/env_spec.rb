# frozen_string_literal: true

RSpec.describe BlueprintConfig::Backend::ENV do
  let(:options) { {} }
  let(:subject) { BlueprintConfig::Backend::ENV.new(options).load_keys }

  before do
    ENV['FOO_BAR'] = 'monkey'
    ENV['TEST'] = 'test'
  end

  context 'when everything is allowed', :aggregate_failures do
    let(:options) { { allow_all: true } }
    it 'copies all env variables' do
      expect(subject[:foo_bar]).to eq('monkey')
    end
  end

  context 'when everything is allowed and keys are nested', :aggregate_failures do
    let(:options) { { allow_all: true, nest: true } }
    it 'copies all env variables nesting em' do
      expect(subject[:foo][:bar]).to eq('monkey')
    end
  end

  context 'when keys are whitelisted', :aggregate_failures do
    let(:options) { { whitelist_keys: [:test] } }
    it 'copies whitelisted keys' do
      expect(subject.keys).to eq([:test])
    end
  end

  context 'when keys are prefix-whitelisted', :aggregate_failures do
    let(:options) { { whitelist_prefixes: %i[foo f] } }
    it 'copies whitelisted keys' do
      expect(subject.keys).to eq([:foo_bar])
    end
  end

  context 'when keys are prefix-whitelisted and', :aggregate_failures do
    let(:options) { { whitelist_prefixes: %i[foo f], nest: true } }
    it 'copies whitelisted keys' do
      expect(subject.keys).to eq([:foo])
    end
  end

  context 'when combines prefix-whitelist and whitelist', :aggregate_failures do
    let(:options) { { whitelist_prefixes: [:foo], whitelist_keys: [:test] } }
    it 'copies whitelisted keys' do
      expect(subject.keys).to eq(%i[test foo_bar])
    end
  end
end
