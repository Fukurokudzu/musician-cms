module ShortCodeable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_external_id, on: :create
  end

  def to_param
    external_id
  end

  private

  def generate_external_id
    return if external_id.present?

    self.external_id = loop do
      code = SecureRandom.alphanumeric(8)
      break code unless self.class.exists?(external_id: code)
    end
  end
end
