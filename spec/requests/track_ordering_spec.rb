require 'rails_helper'

# Every screen that lists the tracks of a release must agree on the order:
# Track.by_position — by position, position-less tracks last.
RSpec.describe 'Track ordering consistency', type: :request do
  let(:artist) { create(:artist, title: 'Fukurokudzu') }
  let(:release) do
    create(:release, :published, artist:, title: 'Ordered Album', allow_zip_download: true)
  end

  # Creation order deliberately differs from the position order, and one track
  # has no position at all.
  let!(:positionless) { create(:track, release:, title: 'Ccc Missing', pos: nil, duration: 60) }
  let!(:second) { create(:track, release:, title: 'Bbb Two', pos: 2, duration: 60) }
  let!(:first) { create(:track, release:, title: 'Aaa One', pos: 1, duration: 60) }

  before do
    [positionless, second, first].each do |track|
      track.audio_file.attach(io: StringIO.new("audio of #{track.title}"), filename: "#{track.title}.mp3")
    end
  end

  # Returns true when every title is present and they appear in the given order
  # (case insensitive: the public release page lowercases the track list).
  def titles_in_order(haystack, titles)
    text = haystack.downcase
    indexes = titles.map { |title| text.index(title.downcase) }
    expect(indexes).to all(be_present), "titles not found in: #{text[0, 300]}"
    indexes == indexes.sort
  end

  it 'lists the tracks in the same order on the public release page' do
    get release_path(release)

    expect(response).to have_http_status(:ok)
    expect(titles_in_order(response.body, ['Aaa One', 'Bbb Two', 'Ccc Missing'])).to be(true)
  end

  it 'lists the tracks in the same order in the admin release view' do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

    get admin_release_path(release), as: :turbo_stream

    expect(titles_in_order(response.body, ['Aaa One', 'Bbb Two', 'Ccc Missing'])).to be(true)
  end

  it 'lists the tracks in the same order in the player json' do
    get track_path(first)

    expect(response.parsed_body['release_tracks'].map { |track| track['title'] })
      .to eq(['Aaa One', 'Bbb Two', 'Ccc Missing'])
  end

  it 'packs the zip in the same order' do
    get download_release_path(release)

    names = []
    Zip::File.open_buffer(StringIO.new(response.body)) { |zip| zip.each { |entry| names << entry.name } }

    expect(names).to eq(
      ['01 Fukurokudzu - Aaa One.mp3',
       '02 Fukurokudzu - Bbb Two.mp3',
       '03 Fukurokudzu - Ccc Missing.mp3']
    )
  end

  it 'walks the player forward through the same order' do
    get "/player/#{first.external_id}", as: :json # stores the current track in the session
    expect(response.parsed_body.dig('track', 'title')).to eq('Aaa One')

    seen = [response.parsed_body.dig('track', 'title')]
    2.times do
      get '/player/next_track', as: :json
      seen << response.parsed_body.dig('track', 'title')
    end

    expect(seen).to eq(['Aaa One', 'Bbb Two', 'Ccc Missing'])
  end
end
