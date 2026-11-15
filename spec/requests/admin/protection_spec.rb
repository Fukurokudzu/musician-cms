require 'rails_helper'

RSpec.describe 'Admin protection', type: :request do
  it 'shows the sign in form on the admin page for guests' do
    get admin_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('admin_password')
  end

  it 'protects admin section endpoints for guests' do
    get admin_releases_path

    expect(response.body).to include('admin_password')
  end

  it 'does not apply theme settings without a session' do
    put admin_themes_path, params: { setting: { accent_color: '#123456' } }

    expect(Setting.accent_color).to eq('#d35400')
  end

  it 'allows signed in admins' do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

    get admin_releases_path

    expect(response.body).not_to include('admin_password')
  end

  it 'asks guests to sign in on every admin tab' do
    [admin_about_path, admin_system_path, admin_library_path, admin_themes_path].each do |path|
      get path, as: :turbo_stream

      expect(response.body).to include('admin_password'), "GET #{path} is not protected"
    end
  end

  it 'does not change system settings without a session' do
    patch admin_system_path, params: { setting: { page_title: 'Hacked Title' } }, as: :turbo_stream

    expect(response.body).to include('admin_password')
    expect(Setting.page_title).not_to eq('Hacked Title')
  end

  it 'does not start a library scan without a session' do
    expect do
      patch admin_library_path, as: :turbo_stream
    end.not_to have_enqueued_job(ScanLibJob)

    expect(response.body).to include('admin_password')
  end

  it 'does not remove the theme background without a session' do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('image'), filename: 'bg.jpg', content_type: 'image/jpeg'
    )
    Setting.background_image = blob.signed_id

    delete admin_themes_path

    expect(response.body).to include('admin_password')
    expect(Setting.background_image).to be_present
  end

  it 'does not touch artists without a session' do
    artist = create(:artist, title: 'Safe Artist')

    patch admin_artist_path(artist), params: { artist: { title: 'Renamed By Guest' } }, as: :turbo_stream
    delete admin_artist_path(artist), as: :turbo_stream

    expect(artist.reload.title).to eq('Safe Artist')
    expect(artist.soft_deleted).to be(false)
  end

  it 'does not touch releases without a session' do
    artist = create(:artist)
    release = create(:release, artist:, title: 'Safe Release')
    track = release.tracks.create!(title: 'Safe Track', pos: 1)

    patch admin_release_path(release), params: { release: { title: 'Renamed By Guest' } }
    delete admin_release_path(release)
    post upload_admin_releases_path, params: { artist_title: 'Guest Artist', release_title: 'Guest Release' }

    expect(release.reload.title).to eq('Safe Release')
    expect(Release.count).to eq(1)
    expect(Track.exists?(track.id)).to be(true)
    expect(Artist.exists?(title: 'Guest Artist')).to be(false)
  end

  it 'does not add tracks to a release without a session' do
    artist = create(:artist)
    release = create(:release, artist:)
    file = Rack::Test::UploadedFile.new(
      begin
        path = File.join(Dir.mktmpdir, 'song.mp3')
        File.write(path, 'audio')
        path
      end,
      'audio/mpeg'
    )

    post add_tracks_admin_release_path(release), params: { tracks: [file] }

    expect(release.tracks.count).to eq(0)
  end
end
