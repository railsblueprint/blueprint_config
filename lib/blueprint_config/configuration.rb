# frozen_string_literal: true

require 'singleton'
require 'blueprint_config/options_hash'
require 'blueprint_config/options_array'

module BlueprintConfig
  class Configuration
    include Singleton

    attr_accessor :config, :backends

    %i[dig dig! fetch \[\] method_missing].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(...)
          reload! unless backends&.fresh?
          config.#{method}(...)
        rescue KeyError => e
          raise KeyError, e.message, caller[1..], cause: nil#{'    '}
        end
      RUBY
    end

    def init(&block)
      backends = BackendCollection.new
      block.call(backends)
      @backends = backends
      reload!
    end

    def refine(&block)
      backends = @backends
      block.call(backends)
      @backends = backends
      reload!
    end

    def reload!
      new_config = @backends.each_with_object(OptionsHash.new) do |backend, config|
        config.deep_merge! OptionsHash.new(backend.load_keys, source: backend.source)
      end

      @config = new_config
      @config = process_erb(new_config)
    end

    def process_erb(object)
      case object
      when String
        if object.start_with?('<%=') && object.end_with?('%>')
          ERB.new(object).result(binding)
        else
          object
        end
      when OptionsArray
        object.each_with_index { |o, index| object[index] = process_erb(o) }
      when OptionsHash
        object.each { |k, v| object[k] = process_erb(v) }
      else
        object
      end
    end

    def set(key, value = nil)
      memory_backend = @backends[:memory]
      raise "Memory backend not configured. Only available in test environment." unless memory_backend

      if key.is_a?(Hash)
        # Handle hash argument: AppConfig.set(foo: { bar: 'baz' })
        key.each do |k, v|
          set(k.to_s, v)
        end
      else
        memory_backend.set(key.to_s, value)
      end
      reload!
    end

    def clear_memory!
      memory_backend = @backends[:memory]
      return unless memory_backend

      memory_backend.clear
      reload!
    end

    def to_h
      reload! unless backends&.fresh?
      config.to_h
    end

    def with_sources
      reload! unless backends&.fresh?
      config.with_sources
    end
  end
end
