require 'rails_helper'

RSpec.describe 'Sidekiq Web', type: :request do
  it 'is not available without admin authorization' do
    get '/sidekiq'

    expect(response).to have_http_status(:not_found)
  end

  it 'is available to an authorized admin' do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

    get '/sidekiq'

    expect(response).to have_http_status(:ok)
  end
end
