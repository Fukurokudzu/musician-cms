class Release < ApplicationRecord
  include ShortCodeable

  belongs_to :artist
  has_many :tracks, dependent: :destroy
  has_one_attached :cover do |attachable|
    attachable.variant :card, resize_to_limit: [400, 400], preprocessed: true
    attachable.variant :thumb, resize_to_limit: [200, 200], preprocessed: true
    attachable.variant :detail, resize_to_limit: [1000, 1000], preprocessed: true
  end
  before_create :set_default_title
  attribute :status, :string
  enum status: { draft: 'draft', published: 'published', archived: 'archived' }

  validates :title, presence: true, uniqueness: { scope: :artist_id }

  scope :active, -> { joins(:artist).where(artists: { soft_deleted: false }) }

  accepts_nested_attributes_for :tracks, allow_destroy: true

  def duration
    tracks.sum(:duration)
  end

  def duration_humanized
    hours = (duration / 3600).floor
    minutes = ((duration % 3600) / 60).floor
    seconds = duration % 60

    if hours.positive?
      format('%d:%02d:%02d', hours, minutes, seconds)
    else
      format('%d:%02d', minutes, seconds)
    end
  end

  def update_plays_count!
    update_column(:plays_count, tracks.sum(:plays_count))
  end

  # Builds a draft track for every uploaded audio file. The title comes from
  # the file name ("<artist> - Song.mp3" becomes "Song") and positions continue
  # after +after_pos+. Returns the created tracks, empty when nothing usable
  # was uploaded.
  def add_tracks!(files, after_pos: 0)
    Array(files).select { |file| file.respond_to?(:original_filename) }.each_with_index.map do |file, index|
      title = Track.title_from_filename(file.original_filename, artist: artist.title)
      tracks.create!(title:, auto_title: title, pos: after_pos + index + 1, status: :draft) do |track|
        track.audio_file.attach(file)
      end
    end
  end

  def artists
    tracks.includes(:artists).flat_map(&:artists).uniq
  end

  def set_default_title
    self.title ||= "Untitled #{FakerTitle.new.title}"
  end
end
