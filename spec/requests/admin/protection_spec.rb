require 'rails_helper'

RSpec.describe 'Admin protection', type: :request do
  it 'shows the sign in form on the admin page for guests' do
    get admin_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('admin_password')
  end

  it 'protects admin section endpoints for guests' do
    get admin_releases_path

    expect(response.body).to include('admin_password')
  end

  it 'does not apply theme settings without a session' do
    put admin_themes_path, params: { setting: { accent_color: '#123456' } }

    expect(Setting.accent_color).to eq('#d35400')
  end

  it 'allows signed in admins' do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

    get admin_releases_path

    expect(response.body).not_to include('admin_password')
  end
end
