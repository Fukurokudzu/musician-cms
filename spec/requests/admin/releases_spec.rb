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

  describe 'POST /admin/releases/upload' do
    let(:artist) { create(:artist, title: 'Existing Artist') }

    before do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
    end

    it 'uploads a release for an existing artist' do
      post upload_admin_releases_path, params: {
        artist_id: artist.id,
        release_title: 'Uploaded Album',
        release_date: '2026-01-05',
        genre: 'ambient',
        publisher: 'Some Label',
        status: 'published'
      }

      release = Release.find_by(title: 'Uploaded Album')
      expect(release).to be_present
      expect(release.artist).to eq(artist)
      expect(release.status).to eq('published')
      expect(release.release_date).to eq(Date.new(2026, 1, 5))
      expect(release.genre).to eq('ambient')
      expect(release.publisher).to eq('Some Label')
      # The success flash is not rendered on this path, the new record shows up
      # in the release list instead.
      expect(response.body).to include('Existing Artist - Uploaded Album')
    end

    it 'defaults to a draft status' do
      post upload_admin_releases_path, params: { artist_id: artist.id, release_title: 'Draft Upload' }

      expect(Release.find_by(title: 'Draft Upload')).to be_draft
    end

    it 'generates a title when the release title is left blank' do
      post upload_admin_releases_path, params: { artist_id: artist.id }

      release = Release.last
      expect(release).to be_persisted
      expect(release.title).to start_with('Untitled ')
    end

    it 'creates a brand new artist when no existing one is chosen' do
      expect do
        post upload_admin_releases_path, params: { artist_title: 'Brand New Artist', release_title: 'First Album' }
      end.to change(Artist, :count).by(1)

      expect(Release.find_by(title: 'First Album').artist.title).to eq('Brand New Artist')
    end

    it 'reports an error when there is no artist to attach the release to' do
      expect do
        post upload_admin_releases_path, params: { release_title: 'Orphan Album' }
      end.not_to change(Release, :count)

      expect(response.body).to match(/Title can(&#39;|')t be blank/)
    end
  end

  describe 'PATCH /admin/releases/:id' do
    let(:artist) { create(:artist, title: 'Fukurokudzu') }
    let(:release) { create(:release, artist:, title: 'Original Album', status: :draft) }
    let!(:first_track) { release.tracks.create!(title: 'First', pos: 1) }
    let!(:second_track) { release.tracks.create!(title: 'Second', pos: 2) }

    before do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
    end

    it 'updates the release fields' do
      patch admin_release_path(release), params: {
        release: {
          title: 'Renamed Album', genre: 'rock', publisher: 'Label',
          release_date: '2025-03-04', status: 'published', allow_zip_download: '1',
          description: 'Some **markdown**'
        }
      }

      expect(response).to have_http_status(:ok)
      expect(release.reload).to be_published
      expect(release.title).to eq('Renamed Album')
      expect(release.genre).to eq('rock')
      expect(release.publisher).to eq('Label')
      expect(release.release_date).to eq(Date.new(2025, 3, 4))
      expect(release).to be_allow_zip_download
      expect(release.description).to eq('Some **markdown**')
    end

    it 'updates and removes nested tracks' do
      patch admin_release_path(release), params: {
        release: {
          tracks_attributes: {
            '0' => { id: first_track.id, title: 'Renamed Track', pos: 5, status: 'published' },
            '1' => { id: second_track.id, _destroy: '1' }
          }
        }
      }

      expect(first_track.reload.title).to eq('Renamed Track')
      expect(first_track.pos).to eq(5)
      expect(first_track.status).to eq('published')
      expect(Track.exists?(second_track.id)).to be(false)
      expect(release.reload.tracks.count).to eq(1)
    end

    it 'attaches a cover when the release has none' do
      cover_file = fixture_file_upload(Rails.root.join('app/assets/images/korg.webp'), 'image/webp')

      expect do
        patch admin_release_path(release), params: { release: { cover: cover_file } }
      end.to change { release.reload.cover.attached? }.from(false).to(true)

      expect(response).to have_http_status(:ok)
      expect(release.reload.cover.blob.filename.to_s).to eq('korg.webp')
    end

    it 'replaces an existing cover' do
      release.cover.attach(io: StringIO.new('first-image'), filename: 'first.png', content_type: 'image/png')
      release.save!
      first_blob_id = release.cover.blob.id

      cover_file = fixture_file_upload(Rails.root.join('app/assets/images/default_cover.png'), 'image/png')
      patch admin_release_path(release), params: { release: { cover: cover_file } }

      expect(response).to have_http_status(:ok)
      expect(release.reload.cover).to be_attached
      expect(release.cover.blob.id).not_to eq(first_blob_id)
      expect(release.cover.blob.filename.to_s).to eq('default_cover.png')
    end

    it 'reports validation errors without changing the release' do
      patch admin_release_path(release), params: { release: { title: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(release.reload.title).to eq('Original Album')
      expect(response.body).to match(/Title can(&#39;|')t be blank/)
    end
  end

  describe 'DELETE /admin/releases/:id' do
    let(:artist) { create(:artist, title: 'Fukurokudzu') }
    let(:release) { create(:release, artist:, title: 'Doomed Album') }
    let!(:track) { release.tracks.create!(title: 'Doomed Track', pos: 1) }

    before do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
    end

    it 'removes the release together with its tracks' do
      expect do
        delete admin_release_path(release)
      end.to change(Release, :count).by(-1).and change(Track, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(Release.exists?(release.id)).to be(false)
    end
  end
end
