require 'rails_helper'

RSpec.describe 'Error pages', type: :request do
  it 'renders a themed 404 with a link to the main page for an unknown URL' do
    get '/definitely-not-a-real-page'

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include('error-container')
    expect(response.body).to include('Back to the main page')
    expect(response.body).to include('href="/"')
    expect(response.body).not_to include('translation_missing')
  end

  it 'renders the themed 404 for an archived release with a link to the main page' do
    artist = create(:artist)
    release = create(:release, artist:, status: :archived)

    get release_path(release)

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include('error-container')
    expect(response.body).to include('href="/"')
  end
end
