require 'rails_helper'

RSpec.describe 'Admin pages smoke test', type: :request do
  let!(:artist) { create(:artist) }
  let!(:release) { create(:release, artist:) }

  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  it 'renders every admin page without errors' do
    turbo_stream_pages = [
      admin_system_path,
      admin_library_path,
      admin_themes_path,
      admin_artists_path,
      admin_releases_path,
      new_admin_artist_path,
      admin_artist_path(artist),
      new_upload_admin_releases_path,
      admin_release_path(release),
      edit_admin_release_path(release)
    ]

    get admin_path
    expect(response).to have_http_status(:ok), "get #{admin_path} => #{response.status}"
    expect(response.body).not_to include('translation_missing'), "#{admin_path} has missing translations"
    expect(response.body).not_to include('Traceback'), "#{admin_path} raised"

    turbo_stream_pages.each do |path|
      get path, as: :turbo_stream
      expect(response).to have_http_status(:ok), "get #{path} (turbo_stream) => #{response.status}"
      expect(response.body).not_to include('translation_missing'), "#{path} has missing translations"
      expect(response.body).not_to include('Traceback'), "#{path} raised"
    end
  end
end
