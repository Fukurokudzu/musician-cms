require 'rails_helper'

RSpec.describe StatsReport do
  describe '#release_page' do
    let(:artist) { create(:artist) }
    let!(:older) { create(:release, artist:, title: 'Older release', created_at: 3.days.ago) }
    let!(:newer) { create(:release, artist:, title: 'Newer release', created_at: 1.day.ago) }

    before do
      create_list(:stat_event, 2, :download, release: older, artist:, created_at: 1.day.ago)
      create_list(:stat_event, 2, :download, release: newer, artist:, created_at: 1.day.ago)
    end

    it 'keeps newest first for equal download totals, like the admin releases list' do
      report = described_class.new(dsort: 'total', ddir: 'desc')

      expect(report.release_page.map(&:id)).to eq([newer.id, older.id])
    end

    it 'still orders unequal download totals by value' do
      create_list(:stat_event, 4, :download, release: older, artist:, created_at: 1.day.ago)
      report = described_class.new(dsort: 'total', ddir: 'desc')

      expect(report.release_page.map(&:id)).to eq([older.id, newer.id])
    end
  end

  describe '#geo_rows' do
    let(:artist) { create(:artist) }
    let(:release) { create(:release, artist:) }

    it 'counts unique visitors from downloads, not only plays' do
      attrs = { release:, artist:, country_code: 'RS', country_name: 'Serbia' }

      3.times do
        create(:stat_event, :download, **attrs, ip_hash: 'same-visitor', created_at: 1.day.ago)
      end
      create(:stat_event, :download, **attrs, ip_hash: 'another-visitor', created_at: 1.day.ago)

      row = described_class.new(range: 'all').geo_rows(limit: nil).find { |r| r.country_code == 'RS' }

      expect(row.downloads).to eq(4)
      expect(row.unique_listeners).to eq(2)
    end
  end
end
