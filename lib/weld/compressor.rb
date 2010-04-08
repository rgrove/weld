require 'open3'

class Weld::Compressor
  autoload :Closure, 'weld/compressor/closure'
  autoload :Yui,     'weld/compressor/yui'

  attr_reader :options, :type

  def initialize(type, options = {})
    @type    = type
    @options = options
  end

  def compress(input)
  end
end
