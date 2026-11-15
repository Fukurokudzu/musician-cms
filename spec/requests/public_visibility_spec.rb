require 'rails_helper'

RSpec.describe 'Public visibility', type: :request do
  let(:artist) { create(:artist, title: 'Visible Artist') }

  def attach_audio(track)
    track.audio_file.attach(io: StringIO.new("audio of #{track.title}"), filename: "#{track.id}.mp3")
    track
  end

  describe 'main page' do
    before do
      create(:release, artist:, title: 'Published Release', status: :published,
                       release_date: Date.new(2025, 6, 1))
      create(:release, artist:, title: 'Draft Release', status: :draft)
      create(:release, artist:, title: 'Archived Release', status: :archived)
    end

    it 'lists published releases only' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Published Release')
      expect(response.body).not_to include('Draft Release')
      expect(response.body).not_to include('Archived Release')
    end

    it 'hides soft deleted artists' do
      create(:artist, title: 'Retired Artist', soft_deleted: true)

      get root_path

      expect(response.body).to include('Visible Artist')
      expect(response.body).not_to include('Retired Artist')
    end

    it 'hides artists that have nothing published' do
      create(:artist, title: 'Silent Artist')
      create(:release, artist: create(:artist, title: 'Draft Only Artist'), status: :draft)

      get root_path

      expect(response.body).not_to include('Silent Artist')
      expect(response.body).not_to include('Draft Only Artist')
    end
  end

  describe 'artist page' do
    it 'groups published releases by year, newest first' do
      create(:release, artist:, title: 'Older Album', status: :published, release_date: Date.new(2023, 1, 1))
      create(:release, artist:, title: 'Newer Album', status: :published, release_date: Date.new(2025, 1, 1))

      get artist_path(artist)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Newer Album')
      expect(response.body).to include('Older Album')
      expect(response.body.index('2025')).to be < response.body.index('2023')
    end

    it 'does not leak draft and archived releases' do
      create(:release, artist:, title: 'Hidden Draft', status: :draft)
      create(:release, artist:, title: 'Hidden Archive', status: :archived)

      get artist_path(artist)

      expect(response.body).not_to include('Hidden Draft')
      expect(response.body).not_to include('Hidden Archive')
      expect(response.body).not_to include('Releases')
    end

    it 'answers with not found for an unknown artist' do
      get artist_path('zzzzzzzz')

      expect(response).to have_http_status(:not_found)
    end

    it 'answers with not found for a soft deleted artist' do
      deleted = create(:artist, title: 'Retired Artist', soft_deleted: true)
      create(:release, artist: deleted, title: 'Old Album', status: :published,
                       release_date: Date.new(2024, 1, 1))

      get artist_path(deleted)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'release page' do
    it 'answers with not found for a draft release' do
      release = create(:release, artist:, title: 'Draft Release', status: :draft)

      expect { get release_path(release) }.not_to raise_error

      expect(response).to have_http_status(:not_found)
    end

    it 'answers with not found for an archived release' do
      release = create(:release, artist:, title: 'Archived Release', status: :archived)

      get release_path(release)

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses the ZIP download of an archived release even when it is allowed' do
      release = create(:release, artist:, status: :archived, allow_zip_download: true)

      get download_release_path(release)

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses the ZIP download of a draft release even when it is allowed' do
      release = create(:release, artist:, status: :draft, allow_zip_download: true)

      get download_release_path(release)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'player' do
    it 'only offers tracks of published releases' do
      playable = attach_audio(create(:track, release: create(:release, :published, artist:, title: 'Published'),
                                             status: :published))
      # The draft track has audio as well, so only the release status decides.
      draft = attach_audio(create(:track,
                                  release: create(:release, artist:, status: :draft, title: 'Unpublished'),
                                  status: :published))

      expect(Track.playable).to contain_exactly(playable)

      get "/player/#{draft.external_id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('track', 'id')).to eq(playable.id)
    end
  end
end
