require 'rails_helper'

RSpec.describe ShortCodeable, type: :model do
  it 'generates an 8 character code for artists' do
    artist = create(:artist)

    expect(artist.external_id).to match(/\A[A-Za-z0-9]{8}\z/)
    expect(artist.to_param).to eq(artist.external_id)
  end

  it 'generates codes for releases and tracks' do
    release = create(:release, artist: create(:artist))
    track = create(:track, release:)

    expect(release.external_id).to match(/\A[A-Za-z0-9]{8}\z/)
    expect(track.external_id).to match(/\A[A-Za-z0-9]{8}\z/)
  end

  it 'does not overwrite an existing code' do
    artist = create(:artist)
    artist.update!(title: 'Renamed')

    expect(artist.reload.external_id).to be_present
  end
end
