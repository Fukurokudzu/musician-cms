require 'rails_helper'

RSpec.describe "Admin::Releases", type: :request do
  def uploaded_file(filename)
    directory = Dir.mktmpdir
    path = File.join(directory, filename)
    File.write(path, 'dummy-audio')
    Rack::Test::UploadedFile.new(path, 'audio/mpeg')
  end

  describe "POST /admin/releases/upload" do
    it "stores track titles without the artist prefix" do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      post upload_admin_releases_path, params: {
        artist_title: 'Fukurokudzu',
        release_title: 'Test Album',
        status: 'draft',
        tracks: [
          uploaded_file('Fukurokudzu - My Bird.mp3'),
          uploaded_file('Some Other Song.mp3')
        ]
      }

      release = Release.find_by(title: 'Test Album')
      expect(release).to be_present
      expect(release.tracks.order(:pos).pluck(:title)).to eq(['My Bird', 'Some Other Song'])
      expect(release.tracks.order(:pos).pluck(:pos)).to eq([1, 2])
    end
  end

  describe "POST /admin/releases/:id/add_tracks" do
    let(:artist) { create(:artist, title: 'Fukurokudzu') }
    let(:release) { create(:release, artist:, title: 'Existing Album') }

    before do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
    end

    it "appends uploaded files to the release as new tracks" do
      release.tracks.create!(title: 'First', pos: 2)

      post add_tracks_admin_release_path(release), params: {
        tracks: [
          uploaded_file('Fukurokudzu - Second.mp3'),
          uploaded_file('Third.mp3')
        ]
      }

      tracks = release.reload.tracks.order(:pos)
      expect(tracks.pluck(:title, :pos)).to eq([['First', 2], ['Second', 3], ['Third', 4]])
      expect(tracks.last.audio_file).to be_attached
      expect(tracks.last.status).to eq('draft')
    end

    it "reports an error when no audio file is selected" do
      tracks_count = release.tracks.count

      post add_tracks_admin_release_path(release), params: { tracks: [''] }

      expect(release.tracks.count).to eq(tracks_count)
      expect(response.body).to include('Select at least one audio file')
    end
  end
end
