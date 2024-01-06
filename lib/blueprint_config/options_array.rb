# frozen_string_literal: true

module BlueprintConfig
  class OptionsArray < Array
    attr_accessor :__sources, :__indeces, :__path

    def initialize(options = [], path: nil, source: nil)
      super() # important - brackets needed to create an empty array
      @__path = path
      @__sources = []
      @__indeces = []
      options.each do |elem|
        __push(elem, source:)
      end
    end

    def __assign(other)
      if other.first.to_s == '__append'
        concat other[1..]
        @__sources.concat other.__sources[1..]
        @__indeces.concat other.__indeces[1..]
      else
        clear
        concat(other)
        __sources.clear
        __sources.concat(other.__sources)
        __indeces.clear
        __indeces.concat(other.__indeces)
      end
      self
    end

    def dig(key, *identifiers)
      super(key, *identifiers)
    end

    def merge!(other, &block)
      @__sources.reverse_merge!(other.__sources) if other.is_a?(OptionsHash)
      super
    end

    def __push(elem, source: nil)
      elem = OptionsHash.new(elem, path: [@__path, size].compact.join('.'), source:) if elem.is_a?(Hash)
      elem = self.class.new(elem, path: [@__path, size].compact.join('.'), source:) if elem.is_a?(Array)
      @__sources.push source
      @__indeces.push size
      push elem
    end

    def source(*args)
      index = args.shift
      if index >= size
        raise IndexError, "Configuration key '#{[@__path, index].compact.join('.')}' is not set", caller[1..],
              cause: nil
      end

      if args.empty?
        "#{@__sources[index]} #{[@__path, @__indeces[index]].compact.join('.')}"
      else
        self[index].source(*args)
      end
    end

    def dig!(*args, &block)
      leading = args.shift
      if args.empty?
        fetch(leading, &block)
      else
        fetch(leading, &block).dig!(*args, &block)
      end
    rescue IndexError => e
      raise e, e.message, caller[1..], cause: nil
    end

    def fetch(index, *args, &block)
      super(index, *args, &block)
    rescue IndexError
      raise IndexError, "Configuration key '#{[@__path, index].compact.join('.')}' is not set", caller[1..], cause: nil
    end
  end
end
