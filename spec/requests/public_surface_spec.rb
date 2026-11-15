require 'rails_helper'

# The public site is read-only: everything that changes content lives behind
# the admin session, and the routes that used to expose those actions (public
# artist mutations, the missing tracks index, the controller-less credentials
# resource) must be gone instead of merely guarded.
RSpec.describe 'Public surface', type: :request do
  let(:artist) { create(:artist) }

  describe 'removed mutation routes' do
    it 'does not expose a public artist creation' do
      post '/artists', params: { artist: { title: 'Guest Artist' } }

      expect(response).to have_http_status(:not_found)
      expect(Artist.exists?(title: 'Guest Artist')).to be(false)
    end

    it 'does not expose a public artist update' do
      patch "/artists/#{artist.id}", params: { artist: { title: 'Hijacked' } }

      expect(response).to have_http_status(:not_found)
      expect(artist.reload.title).not_to eq('Hijacked')
    end

    it 'does not expose a public artist deletion' do
      delete "/artists/#{artist.id}"

      expect(response).to have_http_status(:not_found)
      expect(artist.reload.soft_deleted).to be(false)
    end

    it 'does not expose public release mutations' do
      post '/releases', params: { release: { title: 'Guest Release' } }
      patch "/releases/#{create(:release, artist:).id}", params: { release: { title: 'Hijacked' } }

      expect(response).to have_http_status(:not_found)
      expect(Release.exists?(title: 'Guest Release')).to be(false)
    end
  end

  describe 'routes without an action or a controller' do
    it 'answers not found for the tracks index, which has no view' do
      get '/tracks'

      expect(response).to have_http_status(:not_found)
    end

    it 'answers not found for the credentials resource, which has no controller' do
      get '/admin/credentials'
      put '/admin/credentials', params: { setting: { admin_email: 'stolen@example.com' } }

      expect(response).to have_http_status(:not_found)
      expect(Setting.admin_email).not_to eq('stolen@example.com')
    end
  end

  describe 'read routes that stay' do
    it 'keeps serving the artist page' do
      get artist_path(artist)

      expect(response).to have_http_status(:ok)
    end

    it 'keeps serving the track json for the player' do
      track = create(:track, release: create(:release, :published, artist:), duration: 10, status: :published)
      track.audio_file.attach(io: StringIO.new('audio'), filename: 'song.mp3')

      get track_path(track)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('track', 'id')).to eq(track.id)
      expect(response.parsed_body.dig('track', 'data_src')).to include('active_storage')
    end
  end

  describe 'tracks that cannot be played' do
    it 'answers not found for a track whose audio file is missing' do
      track = create(:track, release: create(:release, :published, artist:), duration: 10)

      get track_path(track)

      expect(response).to have_http_status(:not_found)
    end

    it 'answers not found for a track of an unpublished release' do
      track = create(:track, release: create(:release, artist:, status: :draft), duration: 10)
      track.audio_file.attach(io: StringIO.new('audio'), filename: 'song.mp3')

      get track_path(track)

      expect(response).to have_http_status(:not_found)
    end

    it 'leaves tracks without audio out of the release tracklist' do
      release = create(:release, :published, artist:)
      playable = create(:track, release:, title: 'Playable', pos: 1, duration: 10, status: :published)
      playable.audio_file.attach(io: StringIO.new('audio'), filename: 'song.mp3')
      silent = create(:track, release:, title: 'Silent', pos: 2, duration: 10)

      get track_path(playable)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['release_tracks'].map { |track| track['title'] }).to eq(['Playable'])
      expect(Track.exists?(silent.id)).to be(true)
    end

    it 'keeps the site rendering when no track has audio' do
      create(:track, release: create(:release, :published, artist:), duration: 10)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No tracks available')
    end
  end
end
