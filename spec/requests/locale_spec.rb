require 'rails_helper'

RSpec.describe 'Locale switching', type: :request do
  let(:artist) { create(:artist) }
  let(:release) do
    create(:release, :published, artist:, allow_zip_download: true,
                                 release_date: Date.new(2026, 1, 2))
  end

  before { Setting.locale = 'en' }

  it 'renders the site language from the ?locale= parameter' do
    get release_path(release, locale: 'ru')

    expect(response.body).to include('треков')
    expect(response.body).not_to include('translation_missing')
  end

  it 'lets the parameter override the configured site locale' do
    Setting.locale = 'ru'

    get release_path(release, locale: 'en')

    expect(response.body).to include('tracks:')
    expect(response.body).not_to include('треков')
  end

  it 'ignores an unknown locale parameter and keeps the configured one' do
    Setting.locale = 'ru'

    get release_path(release, locale: 'de')

    expect(response.body).to include('треков')
  end

  it 'falls back to the configured locale without a parameter' do
    Setting.locale = 'ru'

    get release_path(release)

    expect(response.body).to include('треков')
  end

  it 'renders the site language from the ?lang= parameter' do
    get release_path(release, lang: 'ru')

    expect(response.body).to include('треков')
    expect(response.body).not_to include('translation_missing')
  end

  it 'lets ?lang= override the configured site locale' do
    Setting.locale = 'ru'

    get release_path(release, lang: 'en')

    expect(response.body).to include('tracks:')
    expect(response.body).not_to include('треков')
  end

  it 'ignores an unknown lang parameter and keeps the configured one' do
    Setting.locale = 'ru'

    get release_path(release, lang: 'de')

    expect(response.body).to include('треков')
  end

  it 'prefers ?locale= over ?lang= when both are present' do
    get release_path(release, locale: 'en', lang: 'ru')

    expect(response.body).to include('tracks:')
    expect(response.body).not_to include('треков')
  end

  it 'carries the explicit locale into internal links' do
    get release_path(release, locale: 'ru')

    expect(response.body).to include('href="/?locale=ru"')
  end

  it 'carries an aliased ?lang= into internal links as the canonical locale=' do
    get release_path(release, lang: 'ru')

    expect(response.body).to include('href="/?locale=ru"')
  end

  it 'leaves internal links clean without an explicit locale' do
    get release_path(release)

    expect(response.body).to include('href="/"')
    expect(response.body).not_to include('locale=ru')
  end

  it 'falls back to the default locale when the configured one is unusable' do
    Setting.locale = 'de'

    get release_path(release, locale: 'de')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('tracks:')
    expect(response.body).not_to include('translation_missing')
  end
end
