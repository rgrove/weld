require 'fileutils'

class Weld
  HOME_DIR = ENV['WELD_HOME'] || File.join(File.expand_path('~/'), '.weld')
end

$:.unshift(File.dirname(File.expand_path(__FILE__)))
$:.uniq!

require 'weld/cache'
require 'weld/component'
require 'weld/version'

class Weld
  autoload :CDN,        'weld/cdn'
  autoload :CLI,        'weld/cli'
  autoload :Compressor, 'weld/compressor'
  autoload :Server,     'weld/server'

  attr_reader :cache, :config, :config_file

  def initialize(config_file)
    # TODO: handle exceptions
    @config      = YAML::load_file(config_file)
    @config_file = config_file

    # Create home dir if it doesn't exist.
    FileUtils.mkdir_p(HOME_DIR)

    @cache           = Cache.new
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

    @component_cache[name.to_sym] = Component.new(self, name,
        :css      => css,
        :js       => js,
        :requires => requires
    )
  end

  class Error < StandardError; end
  class ComponentNotFoundError < Error; end
  class CompressorError < Error; end
  class ConfigError < Error; end
  class FileNotFoundError < Error; end
  class UnsupportedFileTypeError < Error; end
end
