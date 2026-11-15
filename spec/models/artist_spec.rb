require 'rails_helper'

RSpec.describe Artist, type: :model do
  describe 'validations' do
    it 'requires a title' do
      artist = build(:artist, title: nil)

      expect(artist).not_to be_valid
      expect(artist.errors[:title]).to be_present
    end

    it 'rejects a duplicate title' do
      create(:artist, title: 'Same Name')
      duplicate = build(:artist, title: 'Same Name')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:title]).to be_present
    end

    it 'allows the same title for a soft deleted artist to be renamed away' do
      create(:artist, title: 'Taken')
      artist = create(:artist, title: 'Free')

      expect(artist.update(title: 'Taken')).to be(false)
      expect(artist.update(title: 'Free again')).to be(true)
    end
  end

  describe '.active' do
    it 'excludes soft deleted artists' do
      create(:artist, title: 'Visible Artist')
      create(:artist, title: 'Hidden Artist', soft_deleted: true)

      expect(Artist.active.pluck(:title)).to eq(['Visible Artist'])
    end
  end

  describe '#update_plays_count!' do
    it 'sums the play counts of the artist tracks' do
      artist = create(:artist, plays_count: 0)
      release = create(:release, artist:)
      create(:track, release:, plays_count: 3)
      create(:track, release:, plays_count: 7)

      artist.update_plays_count!

      expect(artist.reload.plays_count).to eq(10)
    end

    it 'resets the counter when the artist has no tracks' do
      artist = create(:artist, plays_count: 42)

      artist.update_plays_count!

      expect(artist.reload.plays_count).to eq(0)
    end
  end

  describe 'roles' do
    it 'exposes the role enum' do
      artist = create(:artist, role: :singer)

      expect(artist).to be_singer
      expect(described_class.roles).to include('producer' => 0, 'band' => 6, 'other' => 7)
    end
  end

  describe 'dependent destroy' do
    it 'removes the artist releases together with their tracks' do
      artist = create(:artist)
      release = create(:release, artist:)
      create(:track, release:)

      expect { artist.destroy }
        .to change(described_class, :count).by(-1)
        .and change(Release, :count).by(-1)
        .and change(Track, :count).by(-1)
    end
  end
end
