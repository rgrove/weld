require 'open-uri'
require 'pathname'

require 'weld/compressor'
require 'weld/version'

class Weld
  autoload :Server, 'weld/server'

  attr_reader :config, :config_file

  def initialize(config_file)
    # TODO: handle exceptions
    @config      = YAML::load_file(config_file)
    @config_file = config_file
    @component_cache = {}
  end

  def component(name)
    return @component_cache[name.to_sym] if @component_cache.has_key?(name.to_sym)

    unless definition = @config['components'][name]
      raise ComponentNotFoundError, "Component not found: #{name}"
    end

    css      = []
    js       = []
    requires = definition['requires'] || []

    # Resolve required components.
    # TODO: handle circular dependencies?
    requires.each do |name|
      component = component(name)

      css += component.css
      js  += component.js
    end

    css += definition['css'] || []
    js  += definition['js'] || []

    Component.new(self, name, :css => css, :js => js, :requires => requires)
  end

  class Component
    attr_reader :name, :requires
    attr_accessor :css, :js

    def initialize(weld, name, config = {})
      raise ArgumentError, "weld must be a Weld instance" unless weld.is_a?(Weld)

      @weld     = weld
      @name     = name
      @css      = config[:css] || []
      @js       = config[:js] || []
      @requires = config[:requires] || []

      @file_cache = {}
    end

    def compress(type)
      compressors = @weld.config['compressors']

      unless compressors && compressors[type.to_s] &&
          compressor_name = compressors[type.to_s]['name'].capitalize.to_sym
        raise CompressorError, "No compressor configured"
      end

      options    = compressors[type.to_s]['options'] || {}
      compressor = Compressor.const_get(compressor_name).new(type, options)

      compressor.compress(merge(type))
    end

    def merge(type)
      raise UnsupportedFileTypeError, "Unsupported file type: #{type}" unless [:css, :js].include?(type.to_sym)

      content = ''
      method(type.to_sym).call.each {|f| content << read_file(f) + "\n" }
      content
    end

    private

    def read_file(filename)
      filename = resolve_file(filename)

      if filename.is_a?(URI)
        open(filename, 'User-Agent' => "#{APP_NAME}/#{APP_VERSION}").read
      else
        File.read(filename)
      end
    end

    def resolve_file(filename)
      return @file_cache[filename] if @file_cache.has_key?(filename)

      if filename =~ /^(?:https?|ftp):\/\//
        @file_cache[filename] = URI.parse(filename)
      else
        (@weld.config['sourcePaths'] || []).each do |source_path|
          full_path = if Pathname.new(source_path).relative?
            File.join(File.dirname(@weld.config_file), source_path, filename)
          else
            File.join(source_path, filename)
          end

          return @file_cache[filename] = File.expand_path(full_path) if File.exist?(full_path)
        end

        raise FileNotFoundError, "File not found: #{filename}"
      end
    end
  end

  class Error < StandardError; end
  class ComponentNotFoundError < Error; end
  class CompressorError < Error; end
  class FileNotFoundError < Error; end
  class UnsupportedFileTypeError < Error; end
end
