# frozen_string_literal: true

RSpec.describe BlueprintConfig::OptionsArray do
  let(:source) do
    %w[a b c]
  end
  subject { described_class.new(source, source: 'env', path: 'path') }

  describe '#initialize' do
    it 'succeeds' do
      expect { subject }.not_to raise_error
    end
  end

  describe 'getting values' do
    it 'retrieves members with []', :aggregate_failures do
      expect(subject[0]).to eq('a')
      expect(subject[1]).to eq('b')
      expect(subject[2]).to eq('c')
    end
  end

  describe '#dig' do
    it 'retrieves members using position', :aggregate_failures do
      expect(subject[0]).to eq('a')
      expect(subject[1]).to eq('b')
      expect(subject[2]).to eq('c')
      expect(subject[3]).to eq(nil)
    end
  end

  describe '#dig!' do
    it 'retrieves members using position', :aggregate_failures do
      expect(subject.dig!(0)).to eq('a')
      expect(subject.dig!(1)).to eq('b')
      expect(subject.dig!(2)).to eq('c')
    end

    it 'raises exception when key not found', :aggregate_failures do
      expect { subject.dig!(3) }.to raise_error(IndexError, "Configuration key 'path.3' is not set")
    end
  end

  describe '#fetch' do
    it 'retrieves members using position', :aggregate_failures do
      expect(subject.fetch(0)).to eq('a')
      expect(subject.fetch(1)).to eq('b')
    end

    it 'raise error when key is not present and no block is given', :aggregate_failures do
      expect { subject.fetch(3) }.to raise_error(IndexError, "Configuration key 'path.3' is not set")
    end

    it 'calls block when it is given and key is not present', :aggregate_failures do
      expect(subject.fetch(3, 1)).to eq(1)
    end
  end

  describe '#source' do
    it 'returns the source', :aggregate_failures do
      expect(subject.source(0)).to eq('env path.0')
      expect(subject.source(1)).to eq('env path.1')
      expect(subject.source(2)).to eq('env path.2')
    end

    context 'when out of range' do
      it 'raises exception', :aggregate_failures do
        expect { subject.source(3) }.to raise_error(IndexError, "Configuration key 'path.3' is not set")
      end
    end

    context 'when merging 2 sources' do
      let(:source1) do
        %w[a b c]
      end
      let(:source2) do
        %w[__append e f]
      end
      let(:options1) { described_class.new(source1, source: 'env1', path: 'path1') }
      let(:options2) { described_class.new(source2, source: 'env2', path: 'path1') }
      subject { options1.__assign(options2) }

      it 'returns the source correctly', :aggregate_failures do
        expect(subject.source(0)).to eq('env1 path1.0')
        expect(subject.source(1)).to eq('env1 path1.1')
        expect(subject.source(2)).to eq('env1 path1.2')
        expect(subject.source(3)).to eq('env2 path1.1')
        expect(subject.source(4)).to eq('env2 path1.2')
      end
    end

    context 'when overriding from different source' do
      let(:source1) do
        %w[a b c]
      end
      let(:source2) do
        %w[e f]
      end
      let(:options1) { described_class.new(source1, source: 'env1') }
      let(:options2) { described_class.new(source2, source: 'env2') }
      subject { options1.__assign(options2) }

      it 'returns the source', :aggregate_failures do
        expect(subject.source(0)).to eq('env2 0')
        expect(subject.source(1)).to eq('env2 1')
      end
    end
  end
end
