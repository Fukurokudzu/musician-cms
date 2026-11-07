require 'rails_helper'

RSpec.describe 'Admin pages smoke test', type: :request do
  let!(:artist) { create(:artist) }
  let!(:release) { create(:release, artist:) }

  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  it 'renders every admin page without errors' do
    [
      [:get, admin_path],
      [:get, admin_system_path],
      [:get, admin_library_path],
      [:get, admin_artists_path],
      [:get, new_admin_artist_path],
      [:get, admin_artist_path(artist)],
      [:get, admin_releases_path],
      [:get, new_upload_admin_releases_path],
      [:get, admin_release_path(release)],
      [:get, edit_admin_release_path(release)],
      [:get, admin_themes_path]
    ].each do |verb, path|
      public_send(verb, path)
      expect(response).to have_http_status(:ok), "#{verb} #{path} => #{response.status}"
      expect(response.body).not_to include('translation_missing'), "#{path} has missing translations"
      expect(response.body).not_to include('Traceback'), "#{path} raised"
    end
  end
end
