class GeoIpUpdateJob < ApplicationJob
  queue_as :default

  # Best-effort refresh of the DB-IP Country Lite database. Safe to enqueue
  # from multiple processes: GeoIp.update! serializes concurrent runs with a
  # file lock and is a no-op if another update is already running.
  def perform
    GeoIp.update!
  rescue StandardError => e
    Rails.logger.error "GeoIpUpdateJob failed: #{e.class}: #{e.message}"
    raise
  end
end
