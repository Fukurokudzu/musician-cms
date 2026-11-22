require 'rails_helper'

RSpec.describe 'Admin statistics export', type: :request do
  include ActiveJob::TestHelper

  let(:artist) { create(:artist, title: 'Export Artist') }
  let(:release) do
    create(:release, :published, artist:, title: 'Export Release', allow_zip_download: true,
                                 release_date: Date.new(2026, 10, 1), genre: 'Rock')
  end
  let!(:track) do
    create(:track, release:, title: 'Export Track', pos: 1, status: :published,
                   duration: 123, created_at: Time.zone.local(2026, 10, 2, 12, 0, 0))
  end

  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  it 'requires admin access for the export endpoints' do
    delete sign_out_path

    post export_admin_stats_path, params: { kind: 'csv' }, as: :turbo_stream
    expect(response.body).to include('admin_password')
    expect(StatsExport.count).to eq(0)

    get export_download_admin_stats_path(id: 1)
    expect(response.body).to include('admin_password')
  end

  it 'enqueues an export job and swaps in the pending panel' do
    ActiveJob::Base.queue_adapter = :test

    expect do
      post export_admin_stats_path, params: { kind: 'xlsx', range: '30' }, as: :turbo_stream
    end.to have_enqueued_job(StatsExportJob)

    export = StatsExport.last
    expect(export.kind).to eq('xlsx')
    expect(export.range).to eq('30')
    expect(export).to be_pending

    expect(response.body).to include('stats-export')
    expect(response.body).to include('stats-export-status')
    expect(response.body).to include(export.id.to_s)
  end

  it 'sanitizes the requested kind and range' do
    ActiveJob::Base.queue_adapter = :test
    post export_admin_stats_path, params: { kind: 'evil', range: '9000' }, as: :turbo_stream

    export = StatsExport.last
    expect(export.kind).to eq('csv')
    expect(export.range).to eq('30')
  end

  it 'generates a CSV report the admin can download' do
    perform_enqueued_jobs do
      post export_admin_stats_path, params: { kind: 'csv', range: 'all' }, as: :turbo_stream
    end

    export = StatsExport.last
    expect(export).to be_done
    expect(export.row_count).to be > 0
    expect(export.file).to be_attached

    csv = export.file.download
    expect(csv.bytes.first(3)).to eq([0xEF, 0xBB, 0xBF]) # UTF-8 BOM for Excel
    expect(csv).to include('Export Track')
    expect(csv).to include('Export Release')
    expect(csv).to include('Export Artist')
    expect(csv).to include('Plays (total)')
    expect(csv).to include('Release date')
  end

  it 'generates an XLSX report the admin can download' do
    perform_enqueued_jobs do
      post export_admin_stats_path, params: { kind: 'xlsx', range: '30' }, as: :turbo_stream
    end

    export = StatsExport.last
    expect(export).to be_done
    expect(export.file).to be_attached
    expect(export.file.download.bytesize).to be > 500
    expect(export.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
  end

  it 'reports progress via the export_status endpoint' do
    perform_enqueued_jobs do
      post export_admin_stats_path, params: { kind: 'csv' }, as: :turbo_stream
    end
    export = StatsExport.last

    get export_status_admin_stats_path(id: export.id), as: :json
    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body['status']).to eq('done')
    expect(body['progress']).to eq(100)
    expect(body['download_url']).to eq(export_download_admin_stats_path(export))
  end

  it 'streams the generated file from export_download' do
    perform_enqueued_jobs do
      post export_admin_stats_path, params: { kind: 'csv' }, as: :turbo_stream
    end
    export = StatsExport.last

    get export_download_admin_stats_path(export)
    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Disposition']).to include(export.filename)
    expect(response.body).to include('Export Track')
  end

  it 'refuses the download until the export is done' do
    ActiveJob::Base.queue_adapter = :test
    post export_admin_stats_path, params: { kind: 'csv' }, as: :turbo_stream
    export = StatsExport.last

    get export_download_admin_stats_path(export)
    expect(response).to have_http_status(:not_found)
  end

  it 'renders the export panel on the stats page' do
    turbo_stream_get = lambda { |path, params = {}|
      get path, params:, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    }
    turbo_stream_get.call(admin_stats_path)

    expect(response.body).to include('stats-export-inner')
    expect(response.body).to include('/admin/stats/export?kind=csv')
  end
end
