require 'open-uri'
require 'pathname'

class Weld::Component
  attr_reader :name, :requires
  attr_accessor :css, :js

  def initialize(weld, name, config = {})
    raise ArgumentError, "weld must be a Weld instance" unless weld.is_a?(Weld)

    @weld     = weld
    @name     = name
    @css      = config[:css] || []
    @js       = config[:js] || []
    @requires = config[:requires] || []

    @filename_cache = {}
  end

  def compress(type)
    compressors = @weld.config['compressors']

    unless compressors && compressors[type.to_s] &&
        compressor_name = compressors[type.to_s]['name'].capitalize.to_sym
      raise Weld::CompressorError, "No compressor configured"
    end

    options    = compressors[type.to_s]['options'] || {}
    compressor = Weld::Compressor.const_get(compressor_name).new(type, options)

    compressor.compress(merge(type))
  end

  def merge(type)
    raise Weld::UnsupportedFileTypeError, "Unsupported file type: #{type}" unless [:css, :js].include?(type.to_sym)

    content = ''
    method(type.to_sym).call.each {|f| content << read_file(f) + "\n" }
    content
  end

  private

  def read_file(filename)
    filename = resolve_filename(filename)

    if filename.is_a?(URI)
      if cached = @weld.cache[filename]
        return cached
      end

      open(filename, 'User-Agent' => "#{Weld::APP_NAME}/#{Weld::APP_VERSION}") do |response|
        unless response.status[0] == '200'
          raise Weld::FileNotFoundError, "URL returned HTTP status code #{response.status[0]}: #{filename}"
        end

        expires = response.meta['expires'] ? Time.parse(response.meta['expires']) : nil

        if expires
          @weld.cache.store(filename, response.read, expires)
        else
          response.read
        end
      end
    else
      File.read(filename)
    end
  end

  def resolve_filename(filename)
    return @filename_cache[filename] if @filename_cache.has_key?(filename)

    if filename =~ /^(?:https?|ftp):\/\//
      @filename_cache[filename] = URI.parse(filename)
    else
      (@weld.config['sourcePaths'] || []).each do |source_path|
        full_path = if Pathname.new(source_path).relative?
          File.join(File.dirname(@weld.config_file), source_path, filename)
        else
          File.join(source_path, filename)
        end

        return @filename_cache[filename] = File.expand_path(full_path) if File.exist?(full_path)
      end

      raise Weld::FileNotFoundError, "File not found: #{filename}"
    end
  end
end
