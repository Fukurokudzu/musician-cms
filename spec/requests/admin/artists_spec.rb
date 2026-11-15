require 'rails_helper'

RSpec.describe "Admin::Artists", type: :request do
  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe "GET /admin/artists" do
    it "renders the artists list" do
      create(:artist, title: 'Visible Artist')

      get admin_artists_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Visible Artist')
    end
  end

  describe "POST /admin/artists" do
    it "creates an artist" do
      expect {
        post admin_artists_path, params: { artist: { title: 'New Artist', genre: 'ambient' } }, as: :turbo_stream
      }.to change(Artist, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(Artist.find_by(title: 'New Artist')).to be_present
    end
  end

  describe "PATCH /admin/artists/:id" do
    it "updates an artist" do
      artist = create(:artist, title: 'Old Name')

      patch admin_artist_path(artist), params: { artist: { title: 'Updated Name' } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(artist.reload.title).to eq('Updated Name')
    end
  end

  describe "DELETE /admin/artists/:id" do
    it "soft deletes an artist" do
      artist = create(:artist)

      delete admin_artist_path(artist), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(artist.reload.soft_deleted).to be(true)
    end
  end
end
