require 'rails_helper'

RSpec.describe "Admin::Systems", type: :request do
  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe "GET /admin/system" do
    it "renders the system settings tab" do
      get admin_system_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Security')
    end
  end

  describe "PATCH /admin/system" do
    it "updates general settings" do
      patch admin_system_path,
            params: { setting: { page_title: 'My Music', description: 'Site desc', locale: 'en' } },
            as: :turbo_stream

      expect(response).to have_http_status(:see_other)
      expect(Setting.page_title).to eq('My Music')
      expect(Setting.description).to eq('Site desc')
    end
  end
end
