class Weld::Compressor::Closure < Weld::Compressor
  def initialize(type, options = {})
    super(type, {
      'jar' => File.join(Weld::LIB_DIR, 'vendor', 'closure', 'compiler.jar')
    }.merge(options))

    @args = options['args'] || []

    raise Weld::CompressorError, "Closure Compiler currently only supports JavaScript" unless @type == :js
    raise Weld::CompressorError, "Closure Compiler jar file not specified" unless @options['jar']
    raise Weld::CompressorError, "Closure Compiler jar file not found: #{@options['jar']}" unless File.exist?(@options['jar'])
  end

  def compress(input)
    args = @args.empty? ? '' : " #{@args.join(' ')}"

    Open3.popen3("java -jar '#{@options['jar']}'#{args}") do |stdin, stdout, stderr|
      stdin.write(input)
      stdin.close

      stdout.read
      # TODO: read stderr
      # FIXME: Closure Compiler hangs for some reason and doesn't seem to close
      # the output stream when using --compilation_level ADVANCED_OPTIMIZATIONS.
    end
  end
end
