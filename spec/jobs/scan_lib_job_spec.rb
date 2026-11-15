require 'rails_helper'
require 'tmpdir'

RSpec.describe ScanLibJob, type: :job do
  around do |example|
    Dir.mktmpdir do |dir|
      @library_root = dir
      artist_dir = File.join(dir, 'Test Artist')
      release_dir = File.join(artist_dir, 'Test Release')
      FileUtils.mkdir_p(release_dir)
      File.write(File.join(release_dir, '01 - Track.mp3'), 'audio')
      File.write(File.join(release_dir, 'cover.jpg'), 'cover')
      example.run
    end
  end

  before do
    allow(Setting).to receive(:library_path).and_return(@library_root)
    allow(Setting).to receive(:track_extensions).and_return(['.mp3'])
    allow(Setting).to receive(:cover_filenames).and_return(['cover'])
    allow(Setting).to receive(:cover_extensions).and_return(['.jpg'])
  end

  it 'lists artist folders in the library' do
    expect(ScanLibHelper.get_folders_list(@library_root)).to eq('Test Artist' => File.join(@library_root, 'Test Artist'))
  end

  it 'lists tracks for selected release scan' do
    release_path = File.join(@library_root, 'Test Artist', 'Test Release')
    expect(ScanLibHelper.get_tracks_list(release_path)).to eq(
      '01 - Track.mp3' => File.join(release_path, '01 - Track.mp3')
    )
  end

  it 'finds cover for selected release scan' do
    release_path = File.join(@library_root, 'Test Artist', 'Test Release')
    expect(ScanLibHelper.get_release_cover(release_path)).to eq(File.join(release_path, 'cover.jpg'))
  end

  it 'imports releases and tracks from the library' do
    expect { described_class.perform_now }.to change(Artist, :count).by(1)

    artist = Artist.find_by!(title: 'Test Artist')
    release = artist.releases.find_by!(title: 'Test Release')
    expect(release.tracks.count).to eq(1)
  end
end
