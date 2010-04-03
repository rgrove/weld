require 'digest/sha1'
require 'time'

class Weld::Cache
  CACHE_DIR = File.join(Weld::HOME_DIR, 'cache')

  def initialize
    # Create the cache directory if it doesn't exist.
    FileUtils.mkdir_p(CACHE_DIR)

    purge_expired
  end

  def fetch(key)
    now = Time.now

    Dir["#{CACHE_DIR}/weld.*.#{key_hash(key)}"].each do |filename|
      next unless meta = parse_filename(filename)

      if meta[:expires] <= now
        File.delete(filename)
      else
        return File.read(filename)
      end
    end

    nil
  end

  alias [] fetch

  def store(key, value, expires = Time.now + 1800)
    File.open(File.join(CACHE_DIR, "weld.#{expires.to_i}.#{key_hash(key)}"), 'w') do |f|
      f.write(value)
    end

    value
  end

  alias []= store

  private

  def key_hash(key)
    Digest::SHA1.hexdigest(key.to_s)
  end

  def parse_filename(filename)
    if File.basename(filename) =~ /^weld\.([0-9]+)\.([0-9a-f]{40})$/
      {:expires => Time.at($1.to_i), :hash => $2}
    else
      nil
    end
  end

  # Deletes expired files from the cache.
  def purge_expired
    now = Time.now

    Dir["#{CACHE_DIR}/weld.*"].each do |filename|
      next unless meta = parse_filename(filename)
      File.delete(filename) if meta[:expires] <= now
    end
  end
end
