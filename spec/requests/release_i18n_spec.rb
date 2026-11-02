require 'rails_helper'

RSpec.describe 'Release i18n', type: :request do
  let(:artist) { create(:artist) }
  let(:release) do
    create(:release, artist: artist, allow_zip_download: true,
                     release_date: Date.new(2026, 11, 3), publisher: 'Some Label')
  end

  def sign_in_admin
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe 'public release page' do
    it 'renders English labels instead of missing translations' do
      get release_path(release)

      expect(response.body).to include('Tracks: 0')
      expect(response.body).to include('Duration: 0:00')
      expect(response.body).to include('released on 3 November 2026')
      expect(response.body).to include('by Some Label')
      expect(response.body).to include('Download release')
      expect(response.body).not_to include('translation_missing')
      expect(response.body).not_to include('Translation missing')
    end

    it 'renders Russian labels' do
      allow(Setting).to receive(:locale).and_return('ru')

      get release_path(release)

      expect(response.body).to include('Треков: 0')
      expect(response.body).to include('выпущен 3 ноября 2026')
      expect(response.body).to include('— Some Label')
      expect(response.body).to include('Скачать релиз')
      expect(response.body).not_to include('translation_missing')
      expect(response.body).not_to include('Translation missing')
    end
  end

  describe 'admin download settings' do
    it 'renders the ZIP setting label in English' do
      sign_in_admin

      get edit_admin_release_path(release)

      expect(response.body).to include('Allow downloading the release as ZIP')
      expect(response.body).not_to include('translation_missing')
    end

    it 'renders the ZIP setting and its status in Russian' do
      sign_in_admin
      allow(Setting).to receive(:locale).and_return('ru')

      get edit_admin_release_path(release)
      expect(response.body).to include('Разрешить скачивание релиза в ZIP')

      get admin_release_path(release)
      expect(response.body).to include('Скачивание ZIP: включено')
      expect(response.body).not_to include('translation_missing')
    end
  end
end
