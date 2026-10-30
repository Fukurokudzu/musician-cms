require 'rails_helper'

RSpec.describe 'Artist and release links', type: :request do
  let(:artist) { create(:artist) }
  let!(:release) { create(:release, artist:) }

  it 'links to artist and release pages with short codes on the main page' do
    get root_path

    expect(response.body).to include("/artists/#{artist.external_id}")
    expect(response.body).to include("/releases/#{release.external_id}")
  end

  it 'resolves the artist page by short code' do
    get artist_path(artist)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(artist.title)
  end

  it 'resolves the artist page by numeric id for old links' do
    get artist_path(artist.id)

    expect(response).to have_http_status(:ok)
  end

  it 'resolves the release page by short code' do
    get release_path(release)

    expect(response).to have_http_status(:ok)
  end
end
