# Records a public play or download into stat_events.
#
# stat_events is the single source of truth for statistics. Never raises:
# stats collection must not take down playback or downloads when the database
# hiccups or geo lookup fails.
class StatTracker
  # Builds a stable, non-reversible fingerprint of an IP for unique-visitor
  # counts. Salted with the app secret so hashes are not comparable across
  # installations and cannot be brute-forced back into addresses cheaply.
  def self.ip_hash(ip)
    return nil if ip.blank?

    secret = Rails.application.secret_key_base
    OpenSSL::HMAC.hexdigest('SHA256', secret, ip)
  rescue StandardError
    nil
  end

  def self.record_play(track:, request: nil)
    new(kind: 'play', track:, request:).record
  end

  def self.record_download(release:, request: nil)
    new(kind: 'download', release:, request:).record
  end

  def initialize(kind:, track: nil, release: nil, request: nil)
    @kind = kind
    @track = track
    @release = release || track&.release
    @artist = @release&.artist
    @request = request
  end

  def record
    geo = geo_lookup

    StatEvent.create!(
      kind: @kind,
      track_id: @track&.id,
      release_id: @release&.id,
      artist_id: @artist&.id,
      track_title: @track&.title,
      release_title: @release&.title,
      artist_title: @artist&.title,
      country_code: geo&.country_code,
      country_name: geo&.country_name,
      ip_hash: @request ? self.class.ip_hash(@request.remote_ip) : nil,
      created_at: Time.current
    )
    true
  rescue StandardError => e
    Rails.logger.error("StatTracker failed (#{@kind}): #{e.class}: #{e.message}")
    false
  end

  private

  def geo_lookup
    return nil unless @request

    GeoIp.lookup(@request.remote_ip)
  rescue StandardError => e
    Rails.logger.warn("StatTracker: geo lookup failed: #{e.class}: #{e.message}")
    nil
  end
end
