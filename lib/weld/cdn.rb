class Weld::CDN
  autoload :S3, 'weld/cdn/s3'

  attr_reader :options

  def initialize(options = {})
    @options = options
  end

  def push(filename, type, content)
  end
end
