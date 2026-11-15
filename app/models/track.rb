class Track < ApplicationRecord
  include ShortCodeable

  belongs_to :release
  has_many :artists, through: :release
  has_one_attached :audio_file
  attribute :status, :string
  enum :status, { draft: 'draft', published: 'published', archived: 'archived' }

  validates :title, presence: true

  # Runs before validation so a track created without a title still gets a
  # generated one instead of failing validation (see Release#set_default_title).
  before_validation :set_default_title, on: :create

  # A playable track belongs to a published release and actually has audio:
  # the player builds a URL for the attachment on every page, so a track that
  # lost its file must never be handed out (the library scan can leave one
  # behind when attaching fails).
  scope :published, -> { where(status: 'published') }
  scope :playable, lambda {
    joins(:release).merge(Release.published).where(status: 'published').joins(:audio_file_attachment)
  }

  # All screens list tracks in the same order: by position, tracks without a
  # position come last, ties are broken by creation order.
  scope :by_position, -> { order(Arel.sql('COALESCE(pos, 999999) ASC'), :id) }

  def increment_plays!
    increment!(:plays_count)
    release.increment!(:plays_count)
    artists.each { |artist| artist.increment!(:plays_count) }
  end

  def duration_formatted
    update_duration! unless duration
    return '--:--' unless duration

    minutes = (duration / 60).floor
    seconds = duration % 60
    format('%<minutes>d:%<seconds>02d', minutes: minutes, seconds: seconds)
  end

  def update_duration!
    return unless audio_file.attached?

    file_path = ActiveStorage::Blob.service.send(:path_for, audio_file.key)
    audio = WahWah.open(file_path)
    self.duration = audio.duration.round
    save
  end

  def set_default_title
    self.title = "Untitled #{FakerTitle.new.title}" if title.blank?
  end

  # Title for a track stored as "<artist> - <title>.mp3": the redundant
  # leading "<artist> - " part is dropped ("Fukurokudzu - My Bird.mp3"
  # becomes "My Bird"). Anything else is returned untouched.
  def self.title_from_filename(filename, artist: nil)
    base = File.basename(filename.to_s, File.extname(filename.to_s))
    without_artist_prefix(base, artist)
  end

  # Drops a leading "<artist> - " part of +title+ (dash variants and casing
  # are tolerated). The title is returned unchanged when nothing matches or
  # when stripping would leave it empty.
  def self.without_artist_prefix(title, artist)
    return title if title.blank? || artist.blank?

    stripped = title.sub(/\A#{Regexp.escape(artist.to_s.strip)}\s*[-–—]\s*/i, '').squish
    stripped.presence || title
  end

  # True when the title was changed by hand (it no longer matches the last
  # automatically assigned one) and library rescans must leave it alone.
  def manually_edited_title?
    title.present? && title != auto_title
  end
end
