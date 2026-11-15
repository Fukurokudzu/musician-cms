require 'rails_helper'

RSpec.describe 'Admin::Abouts', type: :request do
  describe 'GET /admin/about' do
    it 'requires a session' do
      get admin_about_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('admin_password')
    end

    it 'renders the diagnostics tab for a signed in admin' do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      get admin_about_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('admin_body')
      expect(response.body).to include('Diagnostics')
      expect(response.body).not_to include('translation_missing')
    end

    it 'redirects a plain html request back to the admin panel' do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      get admin_about_path

      expect(response).to redirect_to(admin_path)
    end

    it 'reports the installed content counters' do
      create(:artist)
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      get admin_about_path, as: :turbo_stream

      expect(response.body).to include('Artists')
      expect(response.body).to include('Ruby')
      expect(response.body).to include(Rails.env)
    end
  end
end
