class Weld::Compressor::Yui < Weld::Compressor
  def initialize(type, options = {})
    super(type, {
      'jar' => File.join(Weld::LIB_DIR, 'vendor', 'yuicompressor', 'yuicompressor.jar')
    }.merge(options))

    raise Weld::CompressorError, "YUI Compressor jar file not specified" unless @options['jar']
    raise Weld::CompressorError, "YUI Compressor jar file not found: #{@options['jar']}" unless File.exist?(@options['jar'])
  end

  def compress(input)
    Open3.popen3("java -jar '#{@options['jar']}' --type #{type}") do |stdin, stdout, stderr|
      stdin.write(input)
      stdin.close

      stdout.read
      # TODO: read stderr
    end
  end
end
