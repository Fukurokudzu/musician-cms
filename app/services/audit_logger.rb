# Writes a single entry into the audit_events table. Never raises: an audit
# failure must not take down the action being audited, it is logged instead.
#
#   AuditLogger.log(action: 'release.uploaded', target: @release,
#                   metadata: { title: @release.title }, request: request)
#
# `request` is optional; when present its remote IP and user agent are stored
# and the admin email becomes the default actor. Without a request (Sidekiq
# jobs) the actor defaults to 'system'.
class AuditLogger
  def self.log(action:, actor: nil, target: nil, metadata: {}, request: nil)
    new(action: action, actor: actor, target: target, metadata: metadata, request: request).log
  end

  def initialize(action:, actor:, target:, metadata:, request:)
    @action = action.to_s.truncate(255)
    @request = request
    @actor = (actor.presence || default_actor).to_s.truncate(255)
    @target_type, @target_id, @target_label = target_fields(target)
    @metadata = sanitize_metadata(metadata)
  end

  def log
    AuditEvent.create!(
      action: @action,
      actor: @actor,
      target_type: @target_type,
      target_id: @target_id,
      target_label: @target_label,
      metadata: @metadata,
      ip_address: @request&.remote_ip,
      user_agent: @request&.user_agent&.truncate(255)
    )
    prune_throttled
    true
  rescue StandardError => e
    Rails.logger.error("Audit log failed (#{@action}): #{e.class}: #{e.message}")
    false
  end

  private

  def default_actor
    return 'system' if @request.nil?

    Setting.admin_email
  rescue StandardError
    'admin'
  end

  def target_fields(target)
    case target
    when nil
      [nil, nil, nil]
    when Hash
      [target[:type]&.to_s&.truncate(255), target[:id]&.to_s&.truncate(255), target[:label]&.to_s&.truncate(255)]
    else
      if target.respond_to?(:to_model)
        record = target.to_model
        label = %i[title name email].filter_map { |attr| record.try(attr) }.first
        type = record.class.name
        id = record.try(:external_id).presence || record.id
        [type, id.to_s.truncate(255), label.to_s.truncate(255).presence]
      else
        [nil, nil, target.to_s.truncate(255)]
      end
    end
  end

  # Never let secrets slip into the audit log.
  SENSITIVE_KEYS = %w[password admin_password token authenticity_token secret].freeze

  def sanitize_metadata(metadata)
    metadata.to_h.each_with_object({}) do |(key, value), result|
      next if key.to_s.downcase.in?(SENSITIVE_KEYS) || key.to_s.downcase.end_with?('password')

      result[key.to_s] = truncate_metadata_value(value)
    end
  rescue StandardError
    { raw: metadata.to_s.truncate(500) }
  end

  def truncate_metadata_value(value)
    case value
    when Numeric, true, false, nil then value
    when Array then value.first(20).map { |v| v.to_s.truncate(120) }
    else value.to_s.truncate(500)
    end
  end

  # Prune at most once an hour; without a cache store the delete itself is
  # a cheap indexed DELETE, so this stays correct in dev/test too.
  def prune_throttled
    if Rails.cache.respond_to?(:fetch)
      Rails.cache.fetch('audit_events/last_prune', expires_in: 1.hour) { AuditEvent.prune! }
    else
      AuditEvent.prune!
    end
  rescue StandardError => e
    Rails.logger.error("AuditEvent throttled prune failed: #{e.class}: #{e.message}")
  end
end
