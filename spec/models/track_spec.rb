require 'rails_helper'
require 'wahwah'

RSpec.describe Track, type: :model do
  let(:artist) { create(:artist, title: 'Fukurokudzu') }

  describe 'validations' do
    it 'generates a title when none is given' do
      track = Track.new(release: create(:release, artist:))

      expect(track).to be_valid
      expect(track.title).to start_with('Untitled ')

      expect { track.save! }.to change(Track, :count).by(1)
      expect(track.reload.title).to start_with('Untitled ')
    end

    it 'generates a title when an empty one is given' do
      track = Track.new(release: create(:release, artist:), title: '')

      expect(track).to be_valid
      expect(track.title).to start_with('Untitled ')
    end

    it 'rejects clearing the title of an existing track' do
      track = create(:track, release: create(:release, artist:), title: 'Named Track')

      expect(track.update(title: '')).to be(false)
      expect(track.reload.title).to eq('Named Track')
    end

    it 'keeps a title that is already set on create' do
      track = Track.new(release: create(:release, artist:), title: 'Real Title')

      track.valid?

      expect(track.title).to eq('Real Title')
    end
  end

  describe '.playable' do
    it 'only contains tracks of published releases that have audio' do
      published = create(:release, :published, artist:)
      draft = create(:release, artist:, status: :draft)
      archived = create(:release, artist:, status: :archived)

      playable = create(:track, release: published)
      playable.audio_file.attach(io: StringIO.new('audio'), filename: 'song.mp3')
      create(:track, release: draft).tap do |track|
        track.audio_file.attach(io: StringIO.new('audio'), filename: 'draft.mp3')
      end
      create(:track, release: archived).tap do |track|
        track.audio_file.attach(io: StringIO.new('audio'), filename: 'archived.mp3')
      end

      expect(Track.playable).to contain_exactly(playable)
    end

    it 'excludes a track of a published release that lost its audio file' do
      release = create(:release, :published, artist:)
      silent = create(:track, release:)

      expect(Track.playable).not_to include(silent)
      expect(Track.count).to eq(1)
    end
  end

  describe '#increment_plays!' do
    it 'bumps the track, release and artist counters' do
      artist = create(:artist, plays_count: 0)
      release = create(:release, artist:, plays_count: 0)
      track = create(:track, release:, plays_count: 0)

      track.increment_plays!

      expect(track.reload.plays_count).to eq(1)
      expect(release.reload.plays_count).to eq(1)
      expect(artist.reload.plays_count).to eq(1)
    end
  end

  describe '#duration_formatted' do
    it 'formats a stored duration' do
      expect(create(:track, release: create(:release, artist:), duration: 90).duration_formatted).to eq('1:30')
      expect(create(:track, release: create(:release, artist:), duration: 3_661).duration_formatted).to eq('61:01')
    end

    it 'returns a placeholder when there is no duration and no audio' do
      track = create(:track, release: create(:release, artist:), duration: nil)

      expect(track.duration_formatted).to eq('--:--')
    end

    it 'reads and stores the duration from the attached audio' do
      track = create(:track, release: create(:release, artist:), duration: nil)
      track.audio_file.attach(io: StringIO.new('audio-bytes'), filename: 'song.mp3')
      allow(WahWah).to receive(:open).and_return(double(duration: 90.6))

      expect(track.duration_formatted).to eq('1:31')
      expect(track.reload.duration).to eq(91)
    end
  end

  describe '#manually_edited_title?' do
    it 'is false while the title still matches the automatic one' do
      track = build(:track, release: create(:release, artist:), title: 'Auto', auto_title: 'Auto')

      expect(track.manually_edited_title?).to be(false)
    end

    it 'is true once the title diverges from the automatic one' do
      track = build(:track, release: create(:release, artist:), title: 'Hand made', auto_title: 'Auto')

      expect(track.manually_edited_title?).to be(true)
    end

    it 'is true when the automatic title was never assigned' do
      track = build(:track, release: create(:release, artist:), title: 'Old school', auto_title: nil)

      expect(track.manually_edited_title?).to be(true)
    end

    it 'is false for a blank title' do
      track = build(:track, release: create(:release, artist:), title: '', auto_title: nil)

      expect(track.manually_edited_title?).to be(false)
    end
  end

  describe '.title_from_filename' do
    it 'drops the artist prefix from the file name' do
      expect(described_class.title_from_filename('Fukurokudzu - My Bird.mp3', artist: 'Fukurokudzu'))
        .to eq('My Bird')
    end

    it 'drops the prefix regardless of casing and dash variant' do
      expect(described_class.title_from_filename('fukurokudzu — My Bird.flac', artist: 'Fukurokudzu'))
        .to eq('My Bird')
    end

    it 'handles a non-latin artist' do
      expect(described_class.title_from_filename('Исполнитель - Моя Птица.mp3', artist: 'Исполнитель'))
        .to eq('Моя Птица')
    end

    it 'keeps a title that does not start with the artist' do
      expect(described_class.title_from_filename('My Bird.mp3', artist: 'Fukurokudzu')).to eq('My Bird')
    end

    it 'keeps the title when the artist prefix would leave it empty' do
      expect(described_class.title_from_filename('Fukurokudzu - .mp3', artist: 'Fukurokudzu')).to be_present
    end

    it 'works without an artist' do
      expect(described_class.title_from_filename('My Bird.mp3')).to eq('My Bird')
    end
  end

  describe '.without_artist_prefix' do
    it 'leaves a plain title untouched' do
      expect(described_class.without_artist_prefix('My Bird', 'Fukurokudzu')).to eq('My Bird')
    end

    it 'does not touch a title of another artist' do
      expect(described_class.without_artist_prefix('Other - My Bird', 'Fukurokudzu')).to eq('Other - My Bird')
    end

    it 'returns blank titles as is' do
      expect(described_class.without_artist_prefix(nil, 'Fukurokudzu')).to be_nil
    end
  end
end
