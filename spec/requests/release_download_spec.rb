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

  def download_zip(release)
    get download_release_path(release)
  end

  describe 'GET /releases/:id/download' do
    context 'when the setting is enabled' do
      let(:release) { create(:release, :published, artist:, title: 'Test Release', allow_zip_download: true) }

      before do
        release.cover.attach(io: StringIO.new('cover-bytes'), filename: 'cover.jpg')

        first = release.tracks.create!(title: 'First song', pos: 1, status: :published)
        first.audio_file.attach(io: StringIO.new('first-audio'), filename: 'first.mp3')

        second = release.tracks.create!(title: 'Second song', pos: 2, status: :published)
        second.audio_file.attach(io: StringIO.new('second-audio'), filename: 'second.flac')
      end

      it 'responds with a zip containing the cover and every track' do
        download_zip(release)

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
        download_zip(release)

        expect(zip_entries(response.body).map { |e| e[:method] }).to all(eq(Zip::Entry::STORED))
      end

      it 'records exactly one download event for a real GET' do
        expect do
          get download_release_path(release)
        end.to change(StatEvent.downloads, :count).by(1)
      end

      it 'does not build the ZIP or record a download event for a prefetch GET' do
        expect(ReleaseZipBuilder).not_to receive(:new)

        expect do
          get download_release_path(release), headers: { 'Purpose' => 'prefetch' }
        end.not_to change(StatEvent.downloads, :count)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).not_to eq('application/zip')
      end

      it 'does not build the ZIP or record a download event for a Turbo prefetch GET' do
        expect(ReleaseZipBuilder).not_to receive(:new)

        expect do
          get download_release_path(release), headers: { 'X-Sec-Purpose' => 'prefetch' }
        end.not_to change(StatEvent.downloads, :count)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).not_to eq('application/zip')
      end

      it 'does not build the ZIP or record a download event for a HEAD request' do
        expect(ReleaseZipBuilder).not_to receive(:new)

        expect do
          head download_release_path(release)
        end.not_to change(StatEvent.downloads, :count)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).not_to eq('application/zip')
      end

      it 'excludes draft and archived tracks from the archive' do
        draft = release.tracks.create!(title: 'Draft song', pos: 3, status: :draft)
        draft.audio_file.attach(io: StringIO.new('draft-audio'), filename: 'draft.mp3')
        archived = release.tracks.create!(title: 'Archived song', pos: 4, status: :archived)
        archived.audio_file.attach(io: StringIO.new('archived-audio'), filename: 'archived.mp3')

        download_zip(release)

        names = zip_entries(response.body).map { |entry| entry[:name] }
        expect(names).to contain_exactly(
          'cover.jpg',
          '01 Fukurokudzu - First song.mp3',
          '02 Fukurokudzu - Second song.flac'
        )
      end

      it 'reuses the attached archive on a repeated download' do
        download_zip(release)
        blob = release.reload.zip_archive.blob

        expect(ReleaseZipBuilder).not_to receive(:new)

        download_zip(release)

        expect(release.reload.zip_archive.blob.id).to eq(blob.id)
      end

      it 'rebuilds the archive after the release changes' do
        download_zip(release)
        old_blob_id = release.reload.zip_archive.blob.id

        release.tracks.first.update!(pos: 7)
        expect(ReleaseZipBuilder).to receive(:new).and_call_original

        download_zip(release)

        expect(release.reload.zip_archive.blob.id).not_to eq(old_blob_id)
      end
    end

    context 'when the setting is disabled' do
      let(:release) { create(:release, :published, artist:, title: 'Test Release', allow_zip_download: false) }

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
      enabled = create(:release, :published, artist:, allow_zip_download: true)
      get release_path(enabled)
      expect(response.body).to include('fa-download')

      link = Nokogiri::HTML(response.body).at_css('.release-download-link')
      expect(link['data-turbo-prefetch']).to eq('false')
      expect(link['data-turbo']).to eq('false')
      expect(link['download']).to be_present

      disabled = create(:release, :published, artist:, allow_zip_download: false)
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
