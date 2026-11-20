require 'maxmind/db'

# Resolves the country of an IP address using a local DB-IP / MaxMind
# Country Lite database (.mmdb). The database is not in the repository:
# fetch it with `bin/rails geoip:update` (free download, no account needed).
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
    end

    private

    def reader
      return @reader if defined?(@reader) && @reader

      path = db_path
      unless path.file?
        @reader = nil
        return nil
      end

      @reader = MaxMind::DB.new(path.to_s, mode: MaxMind::DB::MODE_MEMORY)
    rescue StandardError => e
      Rails.logger.error("GeoIp: failed to open #{path}: #{e.class}: #{e.message}")
      @reader = nil
    end
  end
end
