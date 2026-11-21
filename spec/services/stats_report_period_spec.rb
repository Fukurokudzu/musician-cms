require 'rails_helper'

RSpec.describe StatsReport, 'period columns' do
  let(:artist) { create(:artist) }
  let(:release) { create(:release, artist:, title: 'Period release') }
  let(:track) { create(:track, release:, title: 'Period track', pos: 1, status: :published) }

  before do
    create(:stat_event, :play, track:, release:, artist:, created_at: 2.days.ago)
    create(:stat_event, :play, track:, release:, artist:, created_at: 20.days.ago)
    create(:stat_event, :download, release:, artist:, created_at: 2.days.ago)
    create(:stat_event, :download, release:, artist:, created_at: 20.days.ago)
  end

  it 'recomputes period counts from stat_events for each range' do
    expect(described_class.new(range: '7').summary[:plays_period]).to eq(1)
    expect(described_class.new(range: '7').summary[:downloads_period]).to eq(1)

    expect(described_class.new(range: '30').summary[:plays_period]).to eq(2)
    expect(described_class.new(range: '30').summary[:downloads_period]).to eq(2)
  end

  it 'derives all-time totals from events' do
    summary = described_class.new(range: 'all').summary

    expect(summary[:plays_all_time]).to eq(2)
    expect(summary[:downloads_all_time]).to eq(2)
  end

  it 'recomputes the per-release and per-track period columns for each range' do
    short = described_class.new(range: '7')
    long = described_class.new(range: '30')

    expect(short.release_page.first.period_downloads).to eq(1)
    expect(long.release_page.first.period_downloads).to eq(2)
    expect(short.track_page.first.period_plays).to eq(1)
    expect(long.track_page.first.period_plays).to eq(2)
  end
end

RSpec.describe 'Admin statistics period filter', type: :request do
  let(:artist) { create(:artist) }
  let(:release) { create(:release, artist:, title: 'Period release') }
  let(:track) { create(:track, release:, title: 'Period track', pos: 1, status: :published) }

  before do
    create(:stat_event, :play, track:, release:, artist:, created_at: 2.days.ago)
    create(:stat_event, :play, track:, release:, artist:, created_at: 20.days.ago)
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  def turbo_get(range)
    get admin_stats_path(range:), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body)
  end

  def track_period_cell(doc)
    doc.at_css('.admin-stats-table--tracks tbody tr td:nth-child(3)')&.text&.strip
  end

  it 'renders fresh period values for each range' do
    expect(track_period_cell(turbo_get('7'))).to eq('1')
    expect(track_period_cell(turbo_get('30'))).to eq('2')
  end
end
