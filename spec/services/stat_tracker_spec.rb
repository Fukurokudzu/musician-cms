require 'rails_helper'

RSpec.describe StatTracker do
  let(:artist) { create(:artist, title: 'Tracker Artist') }
  let(:release) { create(:release, :published, artist:, title: 'Tracker Release') }
  let!(:track) { create(:track, release:, title: 'Tracker Track', pos: 1, status: :published) }

  def fake_request(remote_ip: '203.0.113.10', user_agent: 'RSpec')
    instance_double(ActionDispatch::Request, remote_ip:, user_agent:)
  end

  describe '.record_play' do
    it 'creates a play event with denormalized titles and HMAC ip_hash' do
      expect do
        described_class.record_play(track:, request: fake_request)
      end.to change(StatEvent.plays, :count).by(1)

      event = StatEvent.plays.last
      expect(event.track_id).to eq(track.id)
      expect(event.release_id).to eq(release.id)
      expect(event.artist_id).to eq(artist.id)
      expect(event.track_title).to eq('Tracker Track')
      expect(event.release_title).to eq('Tracker Release')
      expect(event.artist_title).to eq('Tracker Artist')
      expect(event.ip_hash).to eq(described_class.ip_hash('203.0.113.10'))
      expect(event.ip_hash).not_to include('203.0.113.10')
    end

    it 'stores the country when GeoIp resolves one' do
      geo = GeoIp::Result.new(country_code: 'BY', country_name: 'Belarus')
      allow(GeoIp).to receive(:lookup).and_return(geo)

      described_class.record_play(track:, request: fake_request)

      event = StatEvent.plays.last
      expect(event.country_code).to eq('BY')
      expect(event.country_name).to eq('Belarus')
    end

    it 'still records the event when GeoIp raises' do
      allow(GeoIp).to receive(:lookup).and_raise(StandardError, 'boom')

      expect do
        described_class.record_play(track:, request: fake_request)
      end.to change(StatEvent.plays, :count).by(1)
      expect(StatEvent.plays.last.country_code).to be_nil
    end

    it 'does not raise when the database explodes' do
      allow(StatEvent).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, 'boom')

      expect(described_class.record_play(track:, request: fake_request)).to be(false)
    end
  end

  describe '.record_download' do
    it 'creates a download event linked to the release' do
      expect do
        described_class.record_download(release:, request: fake_request)
      end.to change(StatEvent.downloads, :count).by(1)

      event = StatEvent.downloads.last
      expect(event.track_id).to be_nil
      expect(event.release_title).to eq('Tracker Release')
    end
  end

  describe '.ip_hash' do
    it 'is stable and secret-dependent' do
      expect(described_class.ip_hash('192.0.2.1')).to eq(described_class.ip_hash('192.0.2.1'))
      expect(described_class.ip_hash('192.0.2.1')).not_to eq(described_class.ip_hash('192.0.2.2'))
    end

    it 'returns nil for blank input' do
      expect(described_class.ip_hash(nil)).to be_nil
      expect(described_class.ip_hash('')).to be_nil
    end
  end
end
