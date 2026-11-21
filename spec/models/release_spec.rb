require 'rails_helper'
require 'rack/test'
require 'tmpdir'

RSpec.describe Release, type: :model do
  let(:artist) { create(:artist, title: 'Fukurokudzu') }

  def uploaded_audio(filename)
    directory = Dir.mktmpdir
    path = File.join(directory, filename)
    File.write(path, 'audio-bytes')
    Rack::Test::UploadedFile.new(path, 'audio/mpeg')
  end

  describe 'validations' do
    it 'generates a title when none is given' do
      release = Release.new(artist:)

      expect(release).to be_valid
      expect(release.title).to start_with('Untitled ')

      expect { release.save! }.to change(Release, :count).by(1)
      expect(release.reload.title).to start_with('Untitled ')
    end

    it 'generates a title when an empty one is given' do
      release = Release.new(artist:, title: '')

      expect(release).to be_valid
      expect(release.title).to start_with('Untitled ')
    end

    it 'rejects clearing the title of an existing release' do
      release = create(:release, artist:, title: 'Named Release')

      expect(release.update(title: '')).to be(false)
      expect(release.reload.title).to eq('Named Release')
    end

    it 'rejects a duplicate title within one artist' do
      create(:release, artist:, title: 'Debut')
      duplicate = build(:release, artist:, title: 'Debut')

      expect(duplicate).not_to be_valid
    end

    it 'allows the same title for another artist' do
      create(:release, artist:, title: 'Debut')
      other = build(:release, artist: create(:artist, title: 'Someone Else'), title: 'Debut')

      expect(other).to be_valid
    end
  end

  describe '#set_default_title' do
    it 'fills in a generated title when the callback runs' do
      release = Release.new(artist:)

      release.send(:set_default_title)

      expect(release.title).to start_with('Untitled ')
    end

    it 'replaces a blank title with a generated one' do
      release = Release.new(artist:, title: '   ')

      release.send(:set_default_title)

      expect(release.title).to start_with('Untitled ')
    end

    it 'keeps a title that is already set' do
      release = Release.new(artist:, title: 'Kept Title')

      release.send(:set_default_title)

      expect(release.title).to eq('Kept Title')
    end
  end

  describe 'statuses' do
    it 'defaults to draft' do
      expect(build(:release, artist:).status).to eq('draft')
    end

    it 'knows its status predicates' do
      expect(build(:release, artist:, status: :published)).to be_published
      expect(build(:release, artist:, status: :archived)).to be_archived
      expect(build(:release, artist:, status: :draft)).to be_draft
    end
  end

  describe '#duration' do
    it 'sums the track durations' do
      release = create(:release, artist:)
      create(:track, release:, duration: 120)
      create(:track, release:, duration: 65)

      expect(release.reload.duration).to eq(185)
    end

    it 'is zero without tracks' do
      expect(create(:release, artist:).duration).to eq(0)
    end
  end

  describe '#duration_humanized' do
    let(:release) { create(:release, artist:) }

    it 'formats seconds and minutes' do
      expect(humanized_duration(0)).to eq('0:00')
      expect(humanized_duration(65)).to eq('1:05')
      expect(humanized_duration(300)).to eq('5:00')
    end

    it 'adds an hours part when the release is long enough' do
      expect(humanized_duration(3725)).to eq('1:02:05')
      expect(humanized_duration(7_200)).to eq('2:00:00')
    end

    def humanized_duration(seconds)
      release.tracks.destroy_all
      create(:track, release:, duration: seconds) if seconds.positive?

      release.reload.duration_humanized
    end
  end

  describe '#add_tracks!' do
    it 'creates draft tracks after the given position and attaches their audio' do
      release = create(:release, artist:)
      release.tracks.create!(title: 'Existing', pos: 2)

      tracks = release.add_tracks!(
        [uploaded_audio('Fukurokudzu - New Song.mp3'), uploaded_audio('Plain Song.mp3')],
        after_pos: 2
      )

      expect(tracks.map { |track| [track.title, track.pos, track.status] })
        .to eq([['New Song', 3, 'draft'], ['Plain Song', 4, 'draft']])
      expect(tracks.last.audio_file).to be_attached
      expect(tracks.first.auto_title).to eq('New Song')
    end

    it 'ignores entries that are not uploaded files' do
      release = create(:release, artist:)

      tracks = release.add_tracks!(['', nil, uploaded_audio('Only One.mp3')])

      expect(tracks.size).to eq(1)
      expect(tracks.first.pos).to eq(1)
    end

    it 'returns an empty list when nothing usable was uploaded' do
      release = create(:release, artist:)

      expect(release.add_tracks!(nil)).to eq([])
      expect(release.add_tracks!([''])).to eq([])
      expect(release.tracks).to be_empty
    end
  end

  describe '#artists' do
    it 'collects the artists of its tracks without duplicates' do
      release = create(:release, artist:)
      create(:track, release:)
      create(:track, release:)

      expect(release.artists).to eq([artist])
    end

    it 'is empty for a release without tracks' do
      expect(create(:release, artist:).artists).to eq([])
    end
  end
end
