require 'maxmind/db'

# Resolves the country of an IP address using a local DB-IP / MaxMind
# Country Lite database (.mmdb). The entrypoint downloads it into the storage
# volume in the background on first boot; the
# `geoip:update` rake task (or the entrypoint's background download) refreshes it.
#
# Everything here is best-effort: a missing database, a private/loopback IP
# or a corrupt file all result in nil, and recording stats must never fail
# because of geo lookup problems.
class GeoIp
  DEFAULT_DB_PATH = Rails.root.join('storage/geoip/dbip-country-lite.mmdb')

  Result = Data.define(:country_code, :country_name)

  class << self
    def db_path
      Pathname.new(ENV['GEOIP_DB_PATH'].presence || DEFAULT_DB_PATH)
    end

    def available?
      db_path.file?
    end

    # Returns a Result or nil. Never raises.
    def lookup(ip)
      return nil if ip.blank?

      address = IPAddr.new(ip)
      return nil if address.private? || address.loopback?

      record = reader&.get(address.to_s)
      return nil unless record.is_a?(Hash)

      country = record['country'] || record['registered_country']
      code = country && country['iso_code']
      return nil if code.blank?

      name = country.dig('names', 'en').presence || code
      Result.new(country_code: code, country_name: name)
    rescue StandardError => e
      Rails.logger.warn("GeoIp lookup failed for #{ip.inspect}: #{e.class}: #{e.message}")
      nil
    end

    # Used by tests and by the geoip:update rake task.
    def reset!
      @reader = nil
      @reader_mtime = nil
    end

    # Downloads/refreshes the DB-IP Country Lite database into `db_path`.
    # Serialized with a file lock so concurrent jobs/processes do not download
    # twice. Raises on failure; safe to call from rake tasks and Sidekiq jobs.
    def update!
      require 'net/http'
      require 'zlib'
      require 'stringio'

      target = db_path
      target.dirname.mkpath

      lock_path = target.dirname.join('.geoip-update.lock')
      lock = File.open(lock_path, File::CREAT | File::RDWR)
      unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        Rails.logger.info('GeoIP: another update is already running, skipping')
        lock.close
        return
      end

      begin
        fetch = lambda do |url, redirects = 5|
          uri = URI.parse(url)
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                          read_timeout: 120, open_timeout: 15) do |http|
            http.get(uri.request_uri)
          end

          case response
          when Net::HTTPSuccess then response.body
          when Net::HTTPRedirection
            raise 'GeoIP: too many redirects' if redirects <= 0

            fetch.call(response['location'], redirects - 1)
          when Net::HTTPNotFound then nil
          else raise "GeoIP: HTTP #{response.code} for #{url}"
          end
        rescue SystemCallError, SocketError, OpenSSL::SSL::SSLError, Timeout::Error, IOError => e
          raise "GeoIP: download failed for #{url}: #{e.class}: #{e.message}"
        end

        today = Date.current
        candidates = (0..11).map { |months_back| today.prev_month(months_back) }

        compressed = nil
        candidates.each do |month|
          url = format('https://download.db-ip.com/free/dbip-country-lite-%<year>04d-%<month>02d.mmdb.gz',
                       year: month.year, month: month.month)
          Rails.logger.info("GeoIP: trying #{url}")
          compressed = fetch.call(url)
          break if compressed
        end

        raise 'GeoIP: no DB-IP Country Lite build found for the last 12 months' unless compressed

        data = begin
          Zlib::GzipReader.new(StringIO.new(compressed)).read
        rescue Zlib::GzipFile::Error => e
          raise "GeoIP: downloaded file is not a valid gzip archive: #{e.message}"
        end
        raise 'GeoIP: downloaded database is empty' if data.empty?

        tmp = "#{target}.tmp.#{Process.pid}"
        File.binwrite(tmp, data)
        File.rename(tmp, target)
        reset!

        size = ActiveSupport::NumberHelper.number_to_human_size(File.size(target))
        message = "GeoIP: installed #{target} (#{size})"
        Rails.logger.info(message)
        puts message
      ensure
        begin
          lock.flock(File::LOCK_UN)
        rescue StandardError
          nil
        end
        lock.close
      end
    end

    private

    def reader
      path = db_path
      unless path.file?
        reset!
        return nil
      end

      # The database can be replaced while the process is running (entrypoint
      # seeding or `geoip:update`). Reopen it when its mtime changes; the reader
      # uses MODE_MEMORY and would otherwise keep serving the old file forever.
      mtime = path.mtime
      return @reader if defined?(@reader) && @reader && @reader_mtime == mtime

      @reader = MaxMind::DB.new(path.to_s, mode: MaxMind::DB::MODE_MEMORY)
      @reader_mtime = mtime
    rescue StandardError => e
      Rails.logger.error("GeoIp: failed to open #{path}: #{e.class}: #{e.message}")
      reset!
    end
  end
end
