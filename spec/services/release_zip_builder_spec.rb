require 'rails_helper'

RSpec.describe ReleaseZipBuilder do
  let(:artist) { create(:artist, title: 'Fukurokudzu') }
  let(:release) { create(:release, artist:, title: 'Test Release') }

  def attach_track(title:, pos: nil, filename: 'song.mp3')
    track = release.tracks.create!(title:, pos:)
    track.audio_file.attach(io: StringIO.new("audio of #{title}"), filename:)
    track
  end

  def entries(body)
    result = []
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      zip.each { |entry| result << { name: entry.name, content: entry.get_input_stream.read } }
    end
    result
  end

  describe '#filename' do
    it 'keeps a safe title untouched' do
      release.title = 'My Album'

      expect(described_class.new(release).filename).to eq('My Album.zip')
    end

    it 'replaces characters that are not allowed in file names' do
      release.title = 'AC/DC: Back in <Black>? "Live"|'

      filename = described_class.new(release).filename

      expect(filename).to end_with('.zip')
      expect(filename).not_to match(%r{[/\\:*?"<>|]})
    end

    it 'truncates a very long title' do
      release.title = 'a' * 500

      filename = described_class.new(release).filename

      expect(filename).to eq("#{'a' * 120}.zip")
      expect(filename.length).to be <= 125
    end

    it 'falls back to a generic name when nothing usable is left' do
      release.title = '///'

      expect(described_class.new(release).filename).to eq('release.zip')
    end
  end

  describe '#call' do
    it 'packs the cover and the tracks ordered by position' do
      release.cover.attach(io: StringIO.new('cover-bytes'), filename: 'cover.jpg')
      second = attach_track(title: 'Second', pos: 2, filename: 'second.mp3')
      first = attach_track(title: 'First', pos: 1, filename: 'first.mp3')
      last = attach_track(title: 'No position', pos: nil, filename: 'third.mp3')

      entries = entries(described_class.new(release).call)

      expect(entries.map { |entry| entry[:name] }).to eq(
        [
          'cover.jpg',
          '01 Fukurokudzu - First.mp3',
          '02 Fukurokudzu - Second.mp3',
          '03 Fukurokudzu - No position.mp3'
        ]
      )
      expect(entries.first[:content]).to eq('cover-bytes')
      expect(entries[1][:content]).to eq('audio of First')
      expect([first, second, last]).to all(be_persisted)
    end

    it 'works without a cover' do
      attach_track(title: 'Only Track', pos: 1)

      entries = entries(described_class.new(release).call)

      expect(entries.map { |entry| entry[:name] }).to eq(['01 Fukurokudzu - Only Track.mp3'])
    end

    it 'skips tracks without an attached audio file' do
      release.tracks.create!(title: 'Silent', pos: 1)
      attach_track(title: 'Loud', pos: 2)

      entries = entries(described_class.new(release).call)

      expect(entries.map { |entry| entry[:name] }).to eq(['02 Fukurokudzu - Loud.mp3'])
    end

    it 'numbers an archive without a cover starting from the tracks' do
      attach_track(title: 'Song', pos: nil)

      entries = entries(described_class.new(release).call)

      expect(entries.map { |entry| entry[:name] }).to eq(['01 Fukurokudzu - Song.mp3'])
    end

    it 'keeps duplicate entry names unique' do
      # Two tracks sharing a position produce the same "01 …" entry name.
      attach_track(title: 'Same', pos: 1)
      attach_track(title: 'Same', pos: 1)

      names = entries(described_class.new(release).call).map { |entry| entry[:name] }

      expect(names).to contain_exactly(
        '01 Fukurokudzu - Same.mp3',
        '01 Fukurokudzu - Same (2).mp3'
      )
    end

    it 'drops unsafe or malformed extensions' do
      attach_track(title: 'Weird', pos: 1, filename: 'weird.verylongextension')

      names = entries(described_class.new(release).call).map { |entry| entry[:name] }

      expect(names).to eq(['01 Fukurokudzu - Weird'])
    end

    it 'lowercases extensions taken from the file name' do
      attach_track(title: 'Loud', pos: 1, filename: 'LOUD.MP3')

      names = entries(described_class.new(release).call).map { |entry| entry[:name] }

      expect(names).to eq(['01 Fukurokudzu - Loud.mp3'])
    end

    it 'falls back to a generic entry name when the track title has no usable characters' do
      release.update!(title: '///')
      track = release.tracks.create!(title: '///', pos: 1)
      track.audio_file.attach(io: StringIO.new('bytes'), filename: 'song.mp3')

      names = entries(described_class.new(release).call).map { |entry| entry[:name] }

      expect(names).to eq(['01 Fukurokudzu - track.mp3'])
      expect(described_class.new(release).filename).to eq('release.zip')
    end
  end
end
