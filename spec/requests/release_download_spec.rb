require 'rails_helper'

RSpec.describe 'Release ZIP download', type: :request do
  let(:artist) { create(:artist) }

  def zip_entries(body)
    entries = []
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      zip.each do |entry|
        entries << { name: entry.name, method: entry.compression_method, content: entry.get_input_stream.read }
      end
    end
    entries
  end

  describe 'GET /releases/:id/download' do
    context 'when the setting is enabled' do
      let(:release) { create(:release, artist:, title: 'Test Release', allow_zip_download: true) }

      before do
        release.cover.attach(io: StringIO.new('cover-bytes'), filename: 'cover.jpg')

        first = release.tracks.create!(title: 'First song', pos: 1)
        first.audio_file.attach(io: StringIO.new('first-audio'), filename: 'first.mp3')

        second = release.tracks.create!(title: 'Second song', pos: 2)
        second.audio_file.attach(io: StringIO.new('second-audio'), filename: 'second.flac')
      end

      it 'responds with a zip containing the cover and every track' do
        get download_release_path(release)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('application/zip')
        expect(response.headers['Content-Disposition']).to include('Test Release.zip')

        entries = zip_entries(response.body)
        expect(entries.map { |e| e[:name] }).to contain_exactly(
          'cover.jpg',
          '01 Fukurokudzu - First song.mp3',
          '02 Fukurokudzu - Second song.flac'
        )
        expect(entries.map { |e| e[:content] }).to contain_exactly(
          'cover-bytes', 'first-audio', 'second-audio'
        )
      end

      it 'stores entries without compression' do
        get download_release_path(release)

        expect(zip_entries(response.body).map { |e| e[:method] }).to all(eq(Zip::Entry::STORED))
      end
    end

    context 'when the setting is disabled' do
      let(:release) { create(:release, artist:, title: 'Test Release', allow_zip_download: false) }

      it 'responds with not found' do
        get download_release_path(release)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'for an unknown release' do
      it 'responds with not found' do
        get download_release_path('unknown-code')

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /releases/:id' do
    it 'shows the download icon only when the setting is enabled' do
      enabled = create(:release, artist:, allow_zip_download: true)
      get release_path(enabled)
      expect(response.body).to include('fa-download')

      disabled = create(:release, artist:, allow_zip_download: false)
      get release_path(disabled)
      expect(response.body).not_to include('fa-download')
    end
  end

  describe 'PATCH /admin/releases/:id' do
    let(:release) { create(:release, artist:, allow_zip_download: false) }

    it 'persists the setting from the edit form' do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      patch admin_release_path(release), params: { release: { allow_zip_download: '1' } }

      expect(release.reload).to be_allow_zip_download
    end
  end
end
