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
    end
  end
end
