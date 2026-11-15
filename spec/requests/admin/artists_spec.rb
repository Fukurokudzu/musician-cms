require 'rails_helper'

RSpec.describe 'Admin::Artists', type: :request do
  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe 'GET /admin/artists' do
    it 'renders the artists list' do
      create(:artist, title: 'Visible Artist')

      get admin_artists_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Visible Artist')
    end

    it 'leaves soft deleted artists out of the list' do
      create(:artist, title: 'Retired Artist', soft_deleted: true)

      get admin_artists_path, as: :turbo_stream

      expect(response.body).not_to include('Retired Artist')
    end
  end

  describe 'POST /admin/artists' do
    it 'creates an artist' do
      expect do
        post admin_artists_path, params: { artist: { title: 'New Artist', genre: 'ambient' } }, as: :turbo_stream
      end.to change(Artist, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(Artist.find_by(title: 'New Artist')).to be_present
    end

    it 'does not create an artist with a taken title' do
      create(:artist, title: 'Duplicate')

      expect do
        post admin_artists_path, params: { artist: { title: 'Duplicate' } }, as: :turbo_stream
      end.not_to change(Artist, :count)

      expect(response.body).to include('Could not create artist')
    end
  end

  describe 'PATCH /admin/artists/:id' do
    it 'updates an artist' do
      artist = create(:artist, title: 'Old Name')

      patch admin_artist_path(artist), params: { artist: { title: 'Updated Name' } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(artist.reload.title).to eq('Updated Name')
    end

    it 'reports a validation error and keeps the artist untouched' do
      create(:artist, title: 'Taken')
      artist = create(:artist, title: 'Mine')

      patch admin_artist_path(artist), params: { artist: { title: 'Taken' } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(artist.reload.title).to eq('Mine')
      expect(response.body).to include('Title has already been taken')
    end
  end

  describe 'DELETE /admin/artists/:id' do
    it 'soft deletes an artist' do
      artist = create(:artist)

      delete admin_artist_path(artist), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(artist.reload.soft_deleted).to be(true)
    end
  end
end
