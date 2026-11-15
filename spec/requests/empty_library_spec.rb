require 'rails_helper'

RSpec.describe 'Player without tracks', type: :request do
  describe 'GET /' do
    it 'renders the main page with the empty player' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No tracks available')
    end

    it 'renders a welcome message instead of a blank library' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Welcome to Musician CMS!')
      expect(response.body).to include('Open admin panel')
      expect(response.body).to include('github.com/Fukurokudzu/musician-cms')
    end

    it 'keeps showing the welcome while only drafts exist' do
      artist = create(:artist, title: 'Draft Artist')
      create(:release, artist:, title: 'Draft Only', status: :draft)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Welcome to Musician CMS!')
      expect(response.body).not_to include('Draft Artist')
    end
  end

  describe 'GET /player/next_track' do
    it 'responds with not found' do
      get '/player/next_track', as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('No tracks available')
    end
  end

  describe 'GET /player/previous_track' do
    it 'responds with not found' do
      get '/player/previous_track', as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /player/:id' do
    it 'responds with not found for an unknown track' do
      get '/player/00000000-0000-0000-0000-000000000000', as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
