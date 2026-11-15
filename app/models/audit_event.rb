# Security/activity audit trail for key admin actions. Written via
# AuditLogger (app/services/audit_logger.rb), displayed on /admin/logs,
# pruned according to Setting.audit_retention_days (0 keeps everything).
class AuditEvent < ApplicationRecord
  CATEGORIES = %w[auth artist release track settings theme library blog].freeze

  scope :recent, -> { order(created_at: :desc) }

  def self.of_category(category)
    return all unless CATEGORIES.include?(category)

    where('action LIKE ?', "#{category}.%")
  end

  def self.prune!
    days = Setting.audit_retention_days
    return 0 if days.blank? || days.to_i <= 0

    where('created_at < ?', days.to_i.days.ago).delete_all
  rescue StandardError => e
    Rails.logger.error("AuditEvent prune failed: #{e.class}: #{e.message}")
    0
  end

  def target
    return nil if target_type.blank? && target_label.blank?

    [target_type, target_label.presence || target_id].compact.join(' ')
  end

  def details
    metadata.map { |key, value| "#{key}: #{truncate_value(value)}" }.join(' · ')
  end

  private

  def truncate_value(value)
    text = value.is_a?(Array) ? value.join(', ') : value.to_s
    text.truncate(120)
  end
end
