class Post < ApplicationRecord
  include ShortCodeable

  validates :title, presence: true

  scope :active, -> { where(soft_deleted: false) }
  scope :recent, -> { order(created_at: :desc) }
end
