require 'open3'

class Weld; class Compressor
  autoload :Yui, 'weld/compressor/yui'

  attr_reader :options, :type

  def initialize(type, options = {})
    @type    = type
    @options = options
  end

  def compress(input)
  end

end; end
