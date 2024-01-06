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
          raise KeyError, e.message, caller[1..], cause: nil    
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
  end
end
