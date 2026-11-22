require 'rails_helper'
require 'tmpdir'

RSpec.describe GeoIp do
  around do |example|
    previous = ENV['GEOIP_DB_PATH']
    Dir.mktmpdir do |dir|
      @geoip_path = File.join(dir, 'test.mmdb')
      File.binwrite(@geoip_path, 'seed')
      ENV['GEOIP_DB_PATH'] = @geoip_path
      described_class.reset!
      example.run
    end
    ENV['GEOIP_DB_PATH'] = previous
    described_class.reset!
  end

  describe '.reader' do
    it 'reopens the database when the file is replaced' do
      allow(MaxMind::DB).to receive(:new) { double('reader') }

      first = described_class.send(:reader)

      File.binwrite(@geoip_path, 'new database')
      future = (Time.zone.now + 60).to_time
      File.utime(future, future, @geoip_path)
      second = described_class.send(:reader)

      expect(second).not_to equal(first)
      expect(MaxMind::DB).to have_received(:new).twice
    end

    it 'returns nil when the database disappears' do
      allow(MaxMind::DB).to receive(:new) { double('reader') }
      expect(described_class.send(:reader)).to be_present

      File.delete(@geoip_path)

      expect(described_class.send(:reader)).to be_nil
    end
  end
end
