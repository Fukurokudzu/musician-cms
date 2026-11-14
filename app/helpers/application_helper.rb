module ApplicationHelper
  # Signed blob of the custom favicon from settings, or nil when unset/invalid.
  def custom_favicon_blob
    return nil if Setting.favicon.blank?

    ActiveStorage::Blob.find_signed(Setting.favicon)
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
