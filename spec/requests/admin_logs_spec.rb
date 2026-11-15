require 'rails_helper'

RSpec.describe 'Admin logs', type: :request do
  def sign_in_admin!
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  def turbo_stream_get(path)
    get path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
  end

  it 'requires admin access' do
    get admin_logs_path
    expect(response.body).not_to include('admin.logs')
    expect(response.body).to include('admin_password')
  end

  it 'logs the sign-in and shows it on the logs page' do
    sign_in_admin!

    expect(AuditEvent.where(action: 'auth.sign_in').count).to eq(1)

    turbo_stream_get admin_logs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('auth.sign_in')
    expect(response.body).to include('Key actions').or include('Ключевые действия')
  end

  it 'filters entries by category' do
    sign_in_admin!
    AuditLogger.log(action: 'release.uploaded', metadata: { title: 'Speculative Fiction' })

    turbo_stream_get admin_logs_path(category: 'release')
    expect(response.body).to include('release.uploaded')
    expect(response.body).not_to include('<code class="admin-logs-action">auth.sign_in</code>')
  end

  it 'does not render the log inline but offers downloads' do
    sign_in_admin!

    turbo_stream_get admin_logs_path
    expect(response.body).to include('stdout').or include('download')
    expect(response.body).not_to include('<pre class="admin-logs-stdout">')
  end

  describe 'DELETE /admin/logs/clear_audit' do
    it 'requires admin access and deletes nothing' do
      AuditEvent.create!(action: 'release.deleted')

      delete clear_audit_admin_logs_path
      expect(response.body).to include('admin_password')
      expect(AuditEvent.count).to eq(1)
    end

    it 'removes all audit entries but leaves a marker event' do
      sign_in_admin!
      AuditEvent.create!(action: 'release.deleted')
      AuditEvent.create!(action: 'artist.created')

      delete clear_audit_admin_logs_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(AuditEvent.where.not(action: 'logs.audit_cleared')).to be_empty
      marker = AuditEvent.find_by(action: 'logs.audit_cleared')
      expect(marker).to be_present
      expect(marker.metadata['removed']).to be >= 2
    end
  end

  describe 'DELETE /admin/logs/clear_file' do
    it 'truncates the application log file' do
      sign_in_admin!
      fake = LogFile::Result.new(path: Pathname.new('/tmp/opencode_fake.log'), exists: true, file_size: 123,
                                 mtime: Time.current)
      allow(LogFile).to receive(:info).and_return(fake)
      expect(File).to receive(:truncate).with(fake.path, 0)

      delete clear_file_admin_logs_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(AuditEvent.where(action: 'logs.file_cleared')).not_to be_empty
    end

    it 'reports an error when the log file is missing' do
      sign_in_admin!
      missing = LogFile::Result.new(path: Pathname.new('/tmp/opencode_missing.log'), exists: false, file_size: 0)
      allow(LogFile).to receive(:info).and_return(missing)

      delete clear_file_admin_logs_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('stdout_missing').or include('not found').or include('не найден')
    end
  end

  describe 'GET /admin/logs/download' do
    it 'requires admin access' do
      get download_admin_logs_path
      expect(response.body).to include('admin_password')
      expect(response.headers['Content-Disposition']).to be_nil
    end

    it 'streams the tail of the log as an attachment' do
      sign_in_admin!

      get download_admin_logs_path
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/plain')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Length'].to_i).to be >= 0
    end

    it 'streams the whole file with scope=full' do
      sign_in_admin!

      get download_admin_logs_path(scope: 'full')
      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Length'].to_i).to eq(File.size(Rails.root.join('log', "#{Rails.env}.log")))
    end

    it 'returns 404 when the log file is missing' do
      sign_in_admin!
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(Rails.root.join('log', "#{Rails.env}.log")).and_return(false)

      get download_admin_logs_path
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'logs a failed sign-in attempt' do
    post sessions_path, params: { admin_email: 'intruder@example.com', admin_password: 'wrong' }

    event = AuditEvent.find_by(action: 'auth.sign_in_failed')
    expect(event).to be_present
    expect(event.metadata['email']).to eq('intruder@example.com')
  end
end
