require 'rails_helper'

RSpec.describe Track, type: :model do
  describe '.title_from_filename' do
    it 'drops the artist prefix from the file name' do
      expect(described_class.title_from_filename('Fukurokudzu - My Bird.mp3', artist: 'Fukurokudzu'))
        .to eq('My Bird')
    end

    it 'drops the prefix regardless of casing and dash variant' do
      expect(described_class.title_from_filename('fukurokudzu — My Bird.flac', artist: 'Fukurokudzu'))
        .to eq('My Bird')
    end

    it 'handles a non-latin artist' do
      expect(described_class.title_from_filename('Исполнитель - Моя Птица.mp3', artist: 'Исполнитель'))
        .to eq('Моя Птица')
    end

    it 'keeps a title that does not start with the artist' do
      expect(described_class.title_from_filename('My Bird.mp3', artist: 'Fukurokudzu')).to eq('My Bird')
    end

    it 'keeps the title when the artist prefix would leave it empty' do
      expect(described_class.title_from_filename('Fukurokudzu - .mp3', artist: 'Fukurokudzu')).to be_present
    end

    it 'works without an artist' do
      expect(described_class.title_from_filename('My Bird.mp3')).to eq('My Bird')
    end
  end

  describe '.without_artist_prefix' do
    it 'leaves a plain title untouched' do
      expect(described_class.without_artist_prefix('My Bird', 'Fukurokudzu')).to eq('My Bird')
    end

    it 'does not touch a title of another artist' do
      expect(described_class.without_artist_prefix('Other - My Bird', 'Fukurokudzu')).to eq('Other - My Bird')
    end

    it 'returns blank titles as is' do
      expect(described_class.without_artist_prefix(nil, 'Fukurokudzu')).to be_nil
    end
  end
end
