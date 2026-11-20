require 'net/http'
require 'zlib'
require 'stringio'

# Downloads the free DB-IP Country Lite database (~4 MB, no account or key
# required) and installs it as storage/geoip/dbip-country-lite.mmdb.
# Stats collection works without it — geo breakdowns are simply empty.
#
#   bin/rails geoip:update
#
# Override the target path with GEOIP_DB_PATH. The database is updated monthly
# by DB-IP; re-run this task from cron/systemd timer to keep it fresh.
namespace :geoip do
  desc 'Download the free DB-IP Country Lite database into storage/geoip'
  task update: :environment do
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
    rescue SystemCallError, SocketError, OpenSSL::SSL::SSLError => e
      raise "GeoIP: download failed for #{url}: #{e.class}: #{e.message}"
    end

    target = GeoIp.db_path
    target.dirname.mkpath

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

    abort 'GeoIP: no DB-IP Country Lite build found for the last 12 months' unless compressed

    data = Zlib::GzipReader.new(StringIO.new(compressed)).read

    tmp = "#{target}.tmp"
    File.binwrite(tmp, data)
    File.rename(tmp, target)
    GeoIp.reset!

    size = ActiveSupport::NumberHelper.number_to_human_size(File.size(target))
    puts "GeoIP: installed #{target} (#{size})"
  end

  desc 'Show whether a GeoIP database is present and usable'
  task status: :environment do
    path = GeoIp.db_path
    if path.file?
      size = ActiveSupport::NumberHelper.number_to_human_size(File.size(path))
      puts "GeoIP: database present at #{path} (#{size})"
    else
      puts "GeoIP: no database at #{path}. Run `bin/rails geoip:update`."
    end
  end
end
