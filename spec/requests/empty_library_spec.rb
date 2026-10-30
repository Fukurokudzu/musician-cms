require 'rails_helper'

RSpec.describe 'Player without tracks', type: :request do
  describe 'GET /' do
    it 'renders the main page with the empty player' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No tracks available')
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
