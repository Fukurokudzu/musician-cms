require 'rails_helper'

RSpec.describe 'Admin statistics', type: :request do
  let(:artist) { create(:artist, title: 'Stats Artist') }
  let(:release) { create(:release, :published, artist:, title: 'Stats Release', allow_zip_download: true) }
  let!(:track) { create(:track, release:, title: 'Stats Track', pos: 1, status: :published, plays_count: 7) }

  def sign_in_admin!
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  def turbo_stream_get(path, params = {})
    get path, params:, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
  end

  it 'requires admin access' do
    get admin_stats_path
    expect(response.body).not_to include('admin.stats')
    expect(response.body).to include('admin_password')
  end

  it 'renders the statistics tab for a signed in admin' do
    sign_in_admin!

    turbo_stream_get admin_stats_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Statistics').or include('Статистика')
    expect(response.body).not_to include('translation_missing')
  end

  it 'redirects a plain html request back to the admin panel' do
    sign_in_admin!

    get admin_stats_path

    expect(response).to redirect_to(admin_path)
  end

  it 'shows all-time counters even without events' do
    sign_in_admin!

    turbo_stream_get admin_stats_path

    expect(response.body).to include('Stats Track')
    expect(response.body).to include('Stats Release')
  end

  it 'aggregates events per release, track and country' do
    sign_in_admin!

    create(:stat_event, :play, track:, release:, artist:, ip_hash: 'a' * 64, country_code: 'RU', country_name: 'Russia')
    create(:stat_event, :play, track:, release:, artist:, ip_hash: 'a' * 64, country_code: 'RU', country_name: 'Russia',
                               created_at: 2.days.ago)
    create(:stat_event, :play, track:, release:, artist:, ip_hash: 'b' * 64, country_code: 'DE',
                               country_name: 'Germany')
    create(:stat_event, :download, release:, artist:, ip_hash: 'c' * 64, country_code: 'RU', country_name: 'Russia')

    turbo_stream_get admin_stats_path, range: '30'

    expect(response.body).to include('Stats Release')
    expect(response.body).to include('Russia')
    expect(response.body).to include('Germany')
  end

  it 'sorts the tracks table by the requested column and direction' do
    sign_in_admin!

    create(:track, release:, title: 'Alpha Song', pos: 2, status: :published, plays_count: 1)
    create(:track, release:, title: 'Beta Song', pos: 3, status: :published, plays_count: 999)

    turbo_stream_get admin_stats_path, sort: 'title', dir: 'asc'

    expect(response.body.index('Alpha Song')).to be < response.body.index('Beta Song')

    turbo_stream_get admin_stats_path, sort: 'total', dir: 'desc'

    expect(response.body.index('Beta Song')).to be < response.body.index('Alpha Song')
  end

  it 'ignores bogus sort and range parameters' do
    sign_in_admin!

    turbo_stream_get admin_stats_path, range: 'century', sort: 'drop table', dir: 'sideways', page: '-5', dsort: ';',
                                       ddir: 'x', dpage: 'NaN'

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('translation_missing')
  end

  it 'counts a play and a download event from the public endpoints' do
    track.audio_file.attach(io: StringIO.new('audio'), filename: 'track.mp3')

    expect do
      get "/player/#{track.external_id}", as: :json
    end.to change(StatEvent.plays, :count).by(1)

    release.cover.attach(io: StringIO.new('cover'), filename: 'cover.jpg')
    track.audio_file.attach(io: StringIO.new('audio-2'), filename: 'track2.mp3')

    expect do
      get download_release_path(release)
    end.to change(StatEvent.downloads, :count).by(1)

    download = StatEvent.downloads.last
    expect(download.release_id).to eq(release.id)
    expect(download.release_title).to eq('Stats Release')
    expect(download.ip_hash).to be_present
  end
end
