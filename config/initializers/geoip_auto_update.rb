# Enqueue a background GeoIP database download on boot when none is present.
# Only in production: development/test use `bin/rails geoip:update` manually.
if Rails.env.production?
  Rails.application.config.after_initialize do
    next unless defined?(GeoIp) && defined?(GeoIpUpdateJob)

    begin
      GeoIpUpdateJob.perform_later unless GeoIp.available?
    rescue StandardError => e
      Rails.logger.warn("GeoIP: failed to enqueue auto-update: #{e.class}: #{e.message}")
    end
  end
end
