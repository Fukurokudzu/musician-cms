require 'net/http'
require 'zlib'
require 'stringio'

# Downloads the free DB-IP Country Lite database (~8 MB, no account or key
# required) and installs it as storage/geoip/dbip-country-lite.mmdb.
# Stats collection works without it — geo breakdowns are simply empty.
#
#   bin/rails geoip:update
#
# Override the target path with GEOIP_DB_PATH. The entrypoint may enqueue a
# background update on first boot; this task is for manual refreshes
# (DB-IP publishes a new database monthly).
namespace :geoip do
  desc 'Download the free DB-IP Country Lite database into storage/geoip'
  task update: :environment do
    GeoIp.update!
  end

  desc 'Show whether a GeoIP database is present and usable'
  task status: :environment do
    path = GeoIp.db_path
    if path.file?
      size = ActiveSupport::NumberHelper.number_to_human_size(File.size(path))
      puts "GeoIP: database present at #{path} (#{size})"
    else
      puts "GeoIP: no database at #{path}. Run `bin/rails geoip:update` to install one."
    end
  end
end
