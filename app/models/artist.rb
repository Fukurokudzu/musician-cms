class Artist < ApplicationRecord
  
  has_many :releases, dependent: :destroy

  validates :title, presence: true, uniqueness: true


end
