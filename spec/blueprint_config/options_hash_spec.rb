# frozen_string_literal: true

RSpec.describe BlueprintConfig::OptionsHash do
  let(:source) do
    {
      a: 1,
      b: 2,
      c: {
        d: 1,
        e: 2
      },
      k: [1, 2, 3],
      j: [{ a: 1 }, { b: 2 }]
    }
  end
  subject { described_class.new(source, source: 'env') }

  describe '#initialize' do
    it 'succeeds' do
      expect { subject }.not_to raise_error
    end
  end

  describe 'getting values' do
    it 'retrieves members as method calls', :aggregate_failures do
      expect(subject.a).to eq(1)
      expect(subject.b).to eq(2)
      expect(subject.c.d).to eq(1)
      expect(subject.c.e).to eq(2)
      expect(subject.c.f).to eq(nil)
      expect(subject.d).to eq(nil)
    end

    it 'retrieves members with [] and symbol keys', :aggregate_failures do
      expect(subject[:a]).to eq(1)
      expect(subject[:b]).to eq(2)
      expect(subject[:c][:d]).to eq(1)
      expect(subject[:c][:e]).to eq(2)
      expect(subject[:c][:f]).to eq(nil)
      expect(subject[:d]).to eq(nil)
    end

    it 'retrieves members with [] and string keys', :aggregate_failures do
      expect(subject['a']).to eq(1)
      expect(subject['b']).to eq(2)
      expect(subject['c']['d']).to eq(1)
      expect(subject['c']['e']).to eq(2)
      expect(subject['c']['f']).to eq(nil)
      expect(subject['d']).to eq(nil)
    end

    it 'retrieves members with [] and mixed keys', :aggregate_failures do
      expect(subject[:c]['d']).to eq(1)
      expect(subject['c'][:e]).to eq(2)
      expect(subject['c'][:f]).to eq(nil)
      expect(subject[:c]['f']).to eq(nil)
    end

    it 'retrieves members with [] and array elements', :aggregate_failures do
      expect(subject[:k][0]).to eq(1)
      expect(subject[:k][1]).to eq(2)
      expect(subject[:j][0][:a]).to eq(1)
      expect(subject[:j][1][:b]).to eq(2)
    end
  end

  describe '#dig' do
    it 'retrieves members using string keys', :aggregate_failures do
      expect(subject['a']).to eq(1)
      expect(subject['b']).to eq(2)
      expect(subject.dig('c', 'd')).to eq(1)
      expect(subject.dig('c', 'e')).to eq(2)
      expect(subject.dig('c', 'f')).to eq(nil)
      expect(subject['d']).to eq(nil)
    end

    it 'retrieves members using symbol keys', :aggregate_failures do
      expect(subject[:a]).to eq(1)
      expect(subject[:b]).to eq(2)
      expect(subject.dig(:c, :d)).to eq(1)
      expect(subject.dig(:c, :e)).to eq(2)
      expect(subject.dig(:c, :f)).to eq(nil)
      expect(subject[:d]).to eq(nil)
    end

    it 'retrieves members using mixed keys', :aggregate_failures do
      expect(subject.dig('c', :d)).to eq(1)
      expect(subject.dig(:c, 'e')).to eq(2)
      expect(subject.dig('c', :f)).to eq(nil)
      expect(subject.dig(:c, 'g')).to eq(nil)
    end

    it 'retrieves members with array elements', :aggregate_failures do
      expect(subject.dig(:k, 0)).to eq(1)
      expect(subject.dig(:k, 1)).to eq(2)
      expect(subject.dig(:j, 0, :a)).to eq(1)
      expect(subject.dig(:j, 1, :b)).to eq(2)
    end
  end

  describe '#dig!' do
    it 'retrieves members using string keys', :aggregate_failures do
      expect(subject.dig!('a')).to eq(1)
      expect(subject.dig!('b')).to eq(2)
      expect(subject.dig!('c', 'd')).to eq(1)
      expect(subject.dig!('c', 'e')).to eq(2)
    end

    it 'retrieves members using symbol keys', :aggregate_failures do
      expect(subject.dig!(:a)).to eq(1)
      expect(subject.dig!(:b)).to eq(2)
      expect(subject.dig!(:c, :d)).to eq(1)
      expect(subject.dig!(:c, :e)).to eq(2)
    end

    it 'retrieves members using mixed keys', :aggregate_failures do
      expect(subject.dig!('c', :d)).to eq(1)
      expect(subject.dig!(:c, 'e')).to eq(2)
    end

    it 'retrieves members with array elements', :aggregate_failures do
      expect(subject.dig!(:k, 0)).to eq(1)
      expect(subject.dig!(:k, 1)).to eq(2)
      expect(subject.dig!(:j, 0, :a)).to eq(1)
      expect(subject.dig!(:j, 1, :b)).to eq(2)
    end

    it 'raises exception when key not found', :aggregate_failures do
      expect { subject.dig!('c', 'f') }.to raise_error(KeyError, "Configuration key 'c.f' is not set")
      expect { subject.dig!('d') }.to raise_error(KeyError, "Configuration key 'd' is not set")
      expect { subject.dig!(:j, 1, :c) }.to raise_error(KeyError, "Configuration key 'j.1.c' is not set")
    end
  end

  describe '#fetch' do
    it 'retrieves members using string keys', :aggregate_failures do
      expect(subject.fetch('a')).to eq(1)
      expect(subject.fetch('b')).to eq(2)
    end

    it 'retrieves members using symbol keys', :aggregate_failures do
      expect(subject.fetch(:a)).to eq(1)
      expect(subject.fetch(:b)).to eq(2)
    end

    it 'raise error when key is not present and no block is given', :aggregate_failures do
      expect { subject.fetch('d') }.to raise_error(KeyError, "Configuration key 'd' is not set")
      expect { subject.fetch(:e) }.to raise_error(KeyError, "Configuration key 'e' is not set")
    end

    it 'calls block when it is given and key is not present', :aggregate_failures do
      expect(subject.fetch(:e, 1)).to eq(1)
      expect(subject.fetch('f', 2)).to eq(2)
    end
  end

  describe '#source' do
    it 'returns the source', :aggregate_failures do
      expect(subject.source(:a)).to eq('env a')
      expect(subject.source(:b)).to eq('env b')
      expect(subject.source(:c)).to eq('env c')
      expect(subject.source(:c, :d)).to eq('env c.d')
      expect(subject.source(:c, :e)).to eq('env c.e')
      expect(subject.source(:k, 0)).to eq('env k.0')
      expect(subject.source(:j, 0)).to eq('env j.0')
      expect(subject.source(:j, 0, :a)).to eq('env j.0.a')
    end

    context 'when merging 2 sources' do
      let(:source1) do
        {
          a: 1,
          b: 2,
          c: {
            d: 1,
            e: 2
          },
          k: [1, 2, 3],
          j: [{ a: 1 }, { b: 2 }]
        }
      end
      let(:source2) do
        {
          a: 1,
          g: 3,
          c: {
            d: 2,
            f: 3
          },
          k: [:__append, 4, 5],
          j: [:__append, { x: 1 }, { y: 2 }]
        }
      end
      let(:options1) { described_class.new(source1, source: 'env1') }
      let(:options2) { described_class.new(source2, source: 'env2') }
      subject { options1.deep_merge(options2) }

      it 'returns the source', :aggregate_failures do
        expect(subject.source(:a)).to eq('env1 a')
        expect(subject.source(:b)).to eq('env1 b')
        expect(subject.source(:c)).to eq('env1 c')
        expect(subject.source(:g)).to eq('env2 g')
        expect(subject.source(:c, :d)).to eq('env1 c.d')
        expect(subject.source(:c, :e)).to eq('env1 c.e')
        expect(subject.source(:k, 4)).to eq('env2 k.2')
        expect(subject.source(:j, 0, :a)).to eq('env1 j.0.a')
        expect(subject.source(:j, 3, :y)).to eq('env2 j.2.y')
      end
    end
  end
end
