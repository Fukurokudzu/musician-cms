require 'rails_helper'
require 'fileutils'

RSpec.describe ReleaseManager do
  let!(:artist) { create(:artist, title: 'Fukurokudzu') }
  let(:library_root) { Dir.mktmpdir }
  let(:release_dir) { File.join(library_root, 'Test Album') }
  let(:files) { ['Fukurokudzu - My Bird.mp3'] }

  before do
    FileUtils.mkdir_p(release_dir)
    files.each { |name| File.write(File.join(release_dir, name), 'mp3-bytes') }
    stub_tags
  end

  after do
    FileUtils.remove_entry(library_root) if File.directory?(library_root)
  end

  # filename => track number read from the tags; unlisted files fail to parse
  # and make the scan fall back to the file name
  def stub_tags(tags = {})
    allow(WahWah).to receive(:open) do |path|
      number = tags[File.basename(path)]
      raise StandardError, 'not an audio file' unless number

      double(title: nil, duration: 10, track: number)
    end
  end

  def scan
    described_class.new('Fukurokudzu' => library_root).update_releases
  end

  def release
    Release.find_by(title: 'Test Album')
  end

  def add_file(name)
    File.write(File.join(release_dir, name), 'mp3-bytes')
  end

  describe 'track titles' do
    it 'stores the title taken from the file name without the artist prefix' do
      scan

      track = Track.find_by(release:)
      expect(track.title).to eq('My Bird')
      expect(track.auto_title).to eq('My Bird')
    end

    it 'updates an untouched title when the automatic value changes' do
      scan
      track = Track.last

      allow(WahWah).to receive(:open).and_return(double(title: 'Fresh Tag Title', duration: 10, track: 1))
      scan

      expect(track.reload.title).to eq('Fresh Tag Title')
      expect(track.auto_title).to eq('Fresh Tag Title')
    end

    it 'keeps a manually edited title on rescan' do
      scan
      track = Track.last
      track.update!(title: 'My Custom Name')

      allow(WahWah).to receive(:open).and_return(double(title: 'Fresh Tag Title', duration: 10, track: 1))
      scan

      expect(track.reload.title).to eq('My Custom Name')
      expect(track.auto_title).to eq('Fresh Tag Title')
    end

    it 'keeps titles that were already in place before auto_title existed' do
      scan
      track = Track.last
      track.update_columns(auto_title: nil, title: 'Curated By Hand')

      scan

      expect(track.reload.title).to eq('Curated By Hand')
    end
  end

  describe 'track positions' do
    context 'on the first scan' do
      let(:files) { ['b.mp3', 'a.mp3'] }

      it 'numbers tracks in file name order' do
        scan

        expect(release.tracks.order(:pos).pluck(:title, :pos)).to eq([['a', 1], ['b', 2]])
      end
    end

    context 'when positions were arranged by hand' do
      let(:files) { ['a.mp3', 'b.mp3'] }

      before do
        scan
        release.tracks.find_by(title: 'b').update!(pos: 1)
        release.tracks.find_by(title: 'a').update!(pos: 2)
      end

      it 'keeps them on rescan' do
        scan

        expect(release.tracks.order(:pos).pluck(:title, :pos)).to eq([['b', 1], ['a', 2]])
      end

      it 'never displaces them when a new file carries the same tag number' do
        add_file('c.mp3')
        stub_tags('c.mp3' => 1)

        scan

        expect(release.tracks.order(:pos).pluck(:title, :pos)).to eq([['b', 1], ['a', 2], ['c', 3]])
      end
    end

    context 'when a new file arrives' do
      let(:files) { ['a.mp3', 'b.mp3'] }

      before { scan }

      it 'takes the position from the tags when it is free' do
        add_file('c.mp3')
        stub_tags('c.mp3' => 5)

        scan

        expect(release.tracks.find_by(title: 'c').pos).to eq(5)
      end

      it 'goes to the end when the tag position is already taken' do
        add_file('c.mp3')
        stub_tags('c.mp3' => 1)

        scan

        positions = release.tracks.order(:pos).pluck(:title, :pos)
        expect(positions).to eq([['a', 1], ['b', 2], ['c', 3]])
        expect(positions.map(&:last).uniq.size).to eq(positions.size)
      end
    end
  end

  describe 'release records' do
    it 'fills in the current date when the release has none' do
      scan

      expect(release.release_date).to eq(Date.current)
    end

    it 'keeps a release that already exists next to a newly added one' do
      scan
      FileUtils.mkdir_p(File.join(library_root, 'Another Album'))
      File.write(File.join(library_root, 'Another Album', 'song.mp3'), 'audio')

      expect { scan }.to change(Release, :count).by(1)
      expect(Release.pluck(:title)).to contain_exactly('Test Album', 'Another Album')
    end
  end

  describe 'cover art' do
    before { File.write(File.join(release_dir, 'cover.jpg'), 'cover-v1') }

    it 'attaches the cover that sits next to the tracks' do
      scan

      expect(release.cover).to be_attached
      expect(release.cover.filename.to_s).to eq('cover.jpg')
      expect(release.cover.download).to eq('cover-v1')
    end

    it 'keeps the same cover file on rescan' do
      scan
      blob_id = release.cover.blob.id

      scan

      expect(release.reload.cover.blob.id).to eq(blob_id)
    end

    it 'replaces the cover when its contents change' do
      scan
      blob_id = release.cover.blob.id
      File.write(File.join(release_dir, 'cover.jpg'), 'cover-v2')

      scan

      expect(release.reload.cover.blob.id).not_to eq(blob_id)
      expect(release.cover.download).to eq('cover-v2')
    end
  end

  describe 'removing files from the disk' do
    context 'when a track file is deleted' do
      let(:files) { ['a.mp3', 'b.mp3'] }

      it 'drops the track and purges its audio' do
        scan

        expect do
          FileUtils.rm_f(File.join(release_dir, 'a.mp3'))
          scan
        end.to change(Track, :count).by(-1).and change(ActiveStorage::Blob, :count).by(-1)

        expect(release.tracks.pluck(:title)).to eq(['b'])
        expect(Track.count).to eq(1)
      end
    end

    context 'when the release folder is deleted' do
      it 'drops the release together with its tracks' do
        scan

        expect do
          FileUtils.remove_entry(release_dir)
          scan
        end.to change(Release, :count).by(-1).and change(Track, :count).by(-1)

        expect(Release.count).to eq(0)
      end
    end
  end
end
