require 'rails_helper'

RSpec.describe 'Tracks API', type: :request do
  let(:artist) { create(:artist, title: 'Fukurokudzu') }
  let(:release) { create(:release, :published, artist:, title: 'Album') }

  def create_track(title, pos)
    track = release.tracks.create!(title:, pos:)
    track.audio_file.attach(io: StringIO.new("audio of #{title}"), filename: "#{title}.mp3")
    track
  end

  describe 'GET /tracks/:id' do
    it 'returns the track and its release tracklist ordered by position' do
      last = create_track('No position', nil)
      second = create_track('Second', 2)
      first = create_track('First', 1)

      get track_path(first)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')

      body = response.parsed_body
      expect(body['track']['id']).to eq(first.id)
      expect(body['track']['external_id']).to eq(first.external_id)
      expect(body['track']['title']).to eq('First')
      expect(body['track']['data_src']).to include('active_storage')
      expect(body['track']['artist']['title']).to eq('Fukurokudzu')
      # Track.by_position is the one order used everywhere: by position, a
      # missing position counts as "after everything else".
      expect(body['release_tracks'].map { |track| track['id'] }).to eq([first.id, second.id, last.id])
      expect(body['release_tracks'].map { |track| track['title'] }).to eq(['First', 'Second', 'No position'])
    end

    it 'resolves a track by its numeric id' do
      track = create_track('By Id', 1)

      get track_path(track.id)

      expect(response.parsed_body.dig('track', 'id')).to eq(track.id)
    end

    it 'answers with not found for an unknown track' do
      get track_path('zzzzzzzz')

      expect(response).to have_http_status(:not_found)
    end
  end
end
