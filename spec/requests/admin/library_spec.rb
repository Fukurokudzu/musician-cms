require 'rails_helper'

RSpec.describe 'Admin::Libraries', type: :request do
  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe 'GET /admin/library' do
    it 'renders the library tab' do
      get admin_library_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('admin_body')
    end
  end

  describe 'PATCH /admin/library' do
    it 'enqueues a library scan job' do
      ActiveJob::Base.queue_adapter = :test

      expect do
        patch admin_library_path, as: :turbo_stream
      end.to have_enqueued_job(ScanLibJob)

      expect(response).to have_http_status(:ok)
    end
  end
end
