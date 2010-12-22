require 'trollop'

class Weld::CLI
  attr_reader :components, :options, :types, :weld

  def initialize
    parse_args

    @weld         = Weld.new(@options[:config])
    @components ||= @weld.config['components'].keys
  end

  def cdn_push(filename, type, content)
    init_cdn
    @cdn.push(filename, type, content)
  end

  def error(message)
    STDERR.puts "Error: #{message}"
  end

  def info(message)
    puts message
  end

  def warn(message)
    STDERR.puts "Warning: #{message}"
  end

  private

  def init_cdn
    return if @cdn

    cdn_config = @weld.config['cdn']

    unless cdn_config && cdn_type = cdn_config['type']
      raise Weld::ConfigError, "No CDN configured"
    end

    @cdn = Weld::CDN.const_get(cdn_type.capitalize.to_sym).new(cdn_config['options'] || {})
  end

  def parse_args
    @options = Trollop.options do
      version "#{Weld::APP_NAME} #{Weld::APP_VERSION}\n" << Weld::APP_COPYRIGHT
      banner <<-EOS
#{Weld::APP_NAME} combines and minifies CSS and JavaScript files at runtime and build time.

Usage:
  weld [options] [<component> ...]

Options:
EOS

      opt :config,       "Use the specified config file.", :short => '-c', :default => './weld.yaml'
      opt :no_minify,    "Don't perform any minification.", :short => :none
      opt :no_timestamp, "Don't append a timestamp to welded filenames.", :short => :none
      opt :output_dir,   "Write welded files to the specified directory.", :short => '-o', :default => './'
      opt :push,         "Push welded files to the configured CDN instead of saving them locally.", :short => '-p'
      opt :type,         "Only weld components of the specified type ('css' or 'js').", :short => '-t', :type => :string
    end

    if @options[:type_given] && !['css', 'js'].include?(@options[:type])
      abort "Error: Unsupported component type: #{@options[:type]}\n" <<
          "Try --help for help."
    end

    @components = ARGV.dup if ARGV.length > 0
    @types      = @options[:type_given] ? [@options[:type].to_sym] : [:css, :js]

    @options
  end
end
