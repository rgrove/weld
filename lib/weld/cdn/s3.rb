require 'aws/s3'
require 'stringio'
require 'zlib'

class Weld::CDN::S3 < Weld::CDN
  def initialize(options = {})
    super(options)

    raise Weld::ConfigError, "S3 bucket not specified" unless @options['bucket']

    @options['access_key_id']     ||= ENV['AMAZON_ACCESS_KEY_ID']
    @options['secret_access_key'] ||= ENV['AMAZON_SECRET_ACCESS_KEY']

    AWS::S3::Base.establish_connection!(
      :access_key_id     => @options['access_key_id'],
      :secret_access_key => @options['secret_access_key']
    )

    @bucket = if AWS::S3::Bucket.list.include?(@options['bucket'])
      AWS::S3::Bucket.find(@options['bucket'])
    else
      AWS::S3::Bucket.create(@options['bucket'], :access => :public_read)
      AWS::S3::Bucket.find(@options['bucket'])
    end
  end

  def push(filename, type, content)
    content_type = type == :css ? 'text/css' : 'application/javascript'
    prefix       = (@options['prefix'] || {})[type.to_s] || ''
    url_base     = @options['url_base'] || "http://#{@options['bucket']}.s3.amazonaws.com/"

    object_options = {
      :access            => :public_read,
      'Cache-Control'    => 'public,max-age=315360000',
      'Content-Type'     => "#{content_type};charset=utf-8",
      'Expires'          => (Time.now + 315360000).httpdate # 10 years from now
    }

    if @options['gzip']
      content_gzip = StringIO.new

      gzip = Zlib::GzipWriter.new(content_gzip, 9)
      gzip.write(content)
      gzip.close

      object_options['Content-Encoding'] = 'gzip'
    end

    object       = @bucket.new_object
    object.key   = "#{prefix}#{filename}"
    object.value = @options['gzip'] ? content_gzip.string : content

    object.store(object_options)

    File.join(url_base, object.key)
  end
end
