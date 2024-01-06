# frozen_string_literal: true

module BlueprintConfig
  class OptionsHash < Hash
    # include ActiveSupport::DeepMergeable

    attr_accessor :__sources, :__path

    def initialize(options = {}, path: nil, source: nil)
      super() # important - brackets needed to create an empty hash
      @__path = path
      @__sources = {}
      options.each do |key, value|
        __set(key, value, source:)
      end
    end

    def [](key)
      super(key.to_sym)
    end

    def dig(key, *identifiers)
      super(key.to_sym, *identifiers)
    end

    def merge!(other, &block)
      @__sources.reverse_merge!(other.__sources) if other.is_a?(OptionsHash)
      super
    end

    def __set(key, value, source: nil)
      value = self.class.new(value, path: [@__path, key].compact.join('.'), source:) if value.is_a?(Hash)
      value = OptionsArray.new(value, path: [@__path, key].compact.join('.'), source:) if value.is_a?(Array)
      @__sources[key] = source
      self[key.to_sym] = value
    end

    def source(*args)
      key = args.shift
      if args.empty?
        "#{@__sources[key]} #{[@__path, key].compact.join('.')}"
      else
        unless key?(key)
          raise KeyError, "Configuration key '#{[@__path, key].compact.join('.')}' is not set", caller[1..], cause: nil
        end

        self[key].source(*args)
      end
    end

    def dig!(*args, &block)
      leading = args.shift
      if args.empty?
        fetch(leading, &block)
      else
        fetch(leading, &block).dig!(*args, &block)
      end
    rescue KeyError => e
      raise e, e.message, caller[1..], cause: nil
    end

    def method_missing(name, *args)
      name_string = +name.to_s
      if name_string.chomp!('=')
        self[name_string] = args.first
      else
        questions = name_string.chomp!('?')
        if questions
          self[name_string].present?
        else
          bangs = name_string.chomp!('!')

          if bangs
            self[name_string].presence ||
              raise(KeyError, "Configuration key '#{[@__path, name_string].compact.join('.')}' is not set", caller[1..])
          else
            self[name_string]
          end
        end
      end
    end

    def fetch(key, *args, &block)
      super(key.to_sym, *args, &block)
    rescue KeyError
      raise KeyError, "Configuration key '#{[@__path, key].compact.join('.')}' is not set", caller[1..], cause: nil
    end

    # deep_merge methods copied from ActiveSupport to avoid extra dependency
    def deep_merge(other, &block)
      dup.deep_merge!(other, &block)
    end

    def deep_merge!(other, &block)
      merge!(other) do |key, this_val, other_val|
        if this_val.is_a?(BlueprintConfig::OptionsHash) && this_val.deep_merge?(other_val)
          this_val.deep_merge(other_val, &block)
        elsif this_val.is_a?(BlueprintConfig::OptionsArray) && other_val.is_a?(BlueprintConfig::OptionsArray)
          this_val.__assign(other_val, &block)
        elsif block_given?
          block.call(key, this_val, other_val)
        else
          other_val
        end
      end
    end

    def deep_merge?(other)
      other.is_a?(self.class)
    end
  end
end
