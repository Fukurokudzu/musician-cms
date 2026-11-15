require 'rails_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe ArtistManager do
  let(:root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(root) if File.directory?(root) }

  def folder(name)
    path = File.join(root, name)
    FileUtils.mkdir_p(path)
    path
  end

  describe '#create_artists' do
    it 'creates an artist for every folder of the library' do
      folders = { 'First Artist' => folder('First Artist'), 'Second Artist' => folder('Second Artist') }

      expect { described_class.new(folders).create_artists }
        .to change(Artist, :count).by(2)

      expect(Artist.find_by(title: 'First Artist').path).to eq(folders['First Artist'])
    end

    it 'does not duplicate an artist that is already known by its path' do
      path = folder('Known Artist')
      artist = create(:artist, title: 'Old Title', path:)

      described_class.new('Known Artist' => path).create_artists

      expect(Artist.where(path:).count).to eq(1)
      expect(artist.reload.title).to eq('Known Artist')
    end

    it 'reuses an artist known by its title and binds it to the folder' do
      artist = create(:artist, title: 'Known Artist')
      path = folder('Known Artist')

      expect { described_class.new('Known Artist' => path).create_artists }.not_to change(Artist, :count)

      expect(artist.reload.path).to eq(path)
    end

    it 'removes artists that disappeared from the library' do
      create(:artist, title: 'Gone Artist')

      expect { described_class.new({}).create_artists }.to change(Artist, :count).by(-1)
    end

    it 'purges the audio and cover files of removed artists' do
      artist = create(:artist, title: 'Gone Artist')
      release = create(:release, artist:)
      release.cover.attach(io: StringIO.new('cover'), filename: 'cover.jpg')
      track = release.tracks.create!(title: 'Song')
      track.audio_file.attach(io: StringIO.new('audio'), filename: 'song.mp3')

      expect { described_class.new({}).create_artists }.to change(ActiveStorage::Blob, :count).by(-2)
      expect(Artist.exists?(artist.id)).to be(false)
    end
  end

  describe '#remove_deleted_artists' do
    it 'keeps artists whose folder is still present in the library' do
      path = folder('Still Here')
      artist = create(:artist, title: 'Renamed On Disk', path:)

      described_class.new({ 'Still Here' => path }).remove_deleted_artists([])

      expect(Artist.exists?(artist.id)).to be(true)
    end

    it 'keeps artists that are part of the matched ids' do
      artist = create(:artist, title: 'Matched')

      described_class.new({}).remove_deleted_artists([artist.id])

      expect(Artist.exists?(artist.id)).to be(true)
    end

    it 'removes artists whose title and folder are both gone' do
      artist = create(:artist, title: 'Gone', path: '/nowhere')

      described_class.new({ 'Somebody Else' => folder('Somebody Else') }).remove_deleted_artists([])

      expect(Artist.exists?(artist.id)).to be(false)
    end
  end
end
