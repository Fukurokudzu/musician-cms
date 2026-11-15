class Release < ApplicationRecord
  include ShortCodeable

  belongs_to :artist
  has_many :tracks, dependent: :destroy
  # Named variants are preprocessed via Sidekiq (ActiveStorage::TransformJob)
  # on attach; WebP keeps covers small and strips EXIF metadata.
  # :medium is the 1x source (and the smallest file for mobile), :detail is the 2x/retina one.
  WEBP_SAVER = { quality: 90, strip: true }.freeze

  has_one_attached :cover do |attachable|
    attachable.variant :card, resize_to_limit: [400, 400], format: :webp, saver: WEBP_SAVER, preprocessed: true
    attachable.variant :thumb, resize_to_limit: [200, 200], format: :webp, saver: WEBP_SAVER, preprocessed: true
    attachable.variant :medium, resize_to_limit: [500, 500], format: :webp, saver: WEBP_SAVER, preprocessed: true
    attachable.variant :detail, resize_to_limit: [1000, 1000], format: :webp, saver: WEBP_SAVER, preprocessed: true
  end
  attribute :status, :string
  enum :status, { draft: 'draft', published: 'published', archived: 'archived' }

  validates :title, presence: true, uniqueness: { scope: :artist_id }

  accepts_nested_attributes_for :tracks, allow_destroy: true

  # Runs before validation so a release created without a title still gets a
  # generated one instead of failing validation (the callback used to be a
  # before_create, i.e. after validation, and therefore never had a chance).
  before_validation :set_default_title, on: :create

  def duration
    tracks.sum(:duration)
  end

  def duration_humanized(published: false)
    track_list = published ? tracks.published : tracks
    format_duration(track_list.sum(:duration))
  end

  def format_duration(duration)
    hours = (duration / 3600).floor
    minutes = ((duration % 3600) / 60).floor
    seconds = duration % 60

    if hours.positive?
      format('%<hours>d:%<minutes>02d:%<seconds>02d', hours: hours, minutes: minutes, seconds: seconds)
    else
      format('%<minutes>d:%<seconds>02d', minutes: minutes, seconds: seconds)
    end
  end
  private :format_duration

  def update_plays_count!
    update_column(:plays_count, tracks.sum(:plays_count))
  end

  # Builds a track for every uploaded audio file. The title comes from
  # the file name ("<artist> - Song.mp3" becomes "Song") and positions continue
  # after +after_pos+. Tracks inherit the release's status so a release
  # published right away doesn't end up silent (a published release only
  # shows published tracks publicly). Returns the created tracks,
  # empty when nothing usable was uploaded.
  def add_tracks!(files, after_pos: 0)
    Array(files).select { |file| file.respond_to?(:original_filename) }.each_with_index.map do |file, index|
      title = Track.title_from_filename(file.original_filename, artist: artist.title)
      tracks.create!(title:, auto_title: title, pos: after_pos + index + 1, status:) do |track|
        track.audio_file.attach(file)
      end
    end
  end

  def artists
    tracks.includes(:artists).flat_map(&:artists).uniq
  end

  def set_default_title
    self.title = "Untitled #{FakerTitle.new.title}" if title.blank?
  end
end
