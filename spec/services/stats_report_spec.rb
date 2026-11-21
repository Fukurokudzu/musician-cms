require 'rails_helper'

RSpec.describe StatsReport do
  describe '#release_page' do
    let(:artist) { create(:artist) }
    let!(:older) { create(:release, artist:, title: 'Older release', downloads_count: 5, created_at: 3.days.ago) }
    let!(:newer) { create(:release, artist:, title: 'Newer release', downloads_count: 5, created_at: 1.day.ago) }

    it 'keeps newest first for equal download totals, like the admin releases list' do
      report = described_class.new(dsort: 'total', ddir: 'desc')

      expect(report.release_page.map(&:id)).to eq([newer.id, older.id])
    end

    it 'still orders unequal download totals by value' do
      older.update!(downloads_count: 9)
      report = described_class.new(dsort: 'total', ddir: 'desc')

      expect(report.release_page.map(&:id)).to eq([older.id, newer.id])
    end
  end
end
