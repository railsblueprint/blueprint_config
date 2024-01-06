# frozen_string_literal: true

describe BlueprintConfig::Backend::YAML do
  let(:subject) { described_class.new('config/app.yml').load_keys }

  context 'when file exists' do
    context 'when env is not set' do
      it 'returns default section' do
        allow(BlueprintConfig).to receive(:env).and_return(nil)
        expect(subject).to eq(
          {
            array: %w[a b x],
            array2: [{ a: { d: 1, e: 2 }, b: 2 }, { b: 1, c: 3 }, { x: 4, y: 5 }],
            nested: { a: 1, b: 2 }
          }
        )
      end
    end

    context 'when env is set' do
      it 'returns default section merged with env section' do
        allow(BlueprintConfig).to receive(:env).and_return('test')
        expect(subject).to eq(
          {
            array: %w[a b x],
            array2: [{ a: { d: 1, e: 2 }, b: 2 }, { b: 1, c: 3 }, { x: 4, y: 5 }],
            nested: { a: 3, b: 2, c: 4 },
            quox: 'baz',
            envir: "<%= ENV['APP_EXAMPLE'] %>"
          }
        )
      end
    end
  end
end
