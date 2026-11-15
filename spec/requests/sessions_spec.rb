require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'POST /sessions' do
    it 'signs a valid admin in and sends them to the admin panel' do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      expect(response).to redirect_to('/admin')

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Security')
      expect(response.body).not_to include('action="/sessions"')
    end

    it 'rejects a wrong password with a flash message' do
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'wrong' }

      expect(response.body).to include('Email or password are incorrect')
      expect(response.body).to include('flash_toast')
      expect(response).not_to have_http_status(:redirect)
    end

    it 'rejects a wrong email with the same message' do
      post sessions_path, params: { admin_email: 'nobody@example.com', admin_password: 'admin' }

      expect(response.body).to include('Email or password are incorrect')
    end

    it 'does not open the admin area for a failed attempt' do
      post sessions_path, params: { admin_email: 'bad', admin_password: 'bad' }

      get admin_path

      expect(response.body).to include('admin_password')
    end
  end

  describe 'DELETE /sign_out' do
    it 'clears the session and sends the visitor to the main page' do
      create(:release, artist: create(:artist, title: 'Public Artist'), status: :published)
      post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }

      delete sign_out_path

      expect(response).to redirect_to('/')

      follow_redirect!
      expect(response.body).to include('Public Artist')
      expect(response.body).not_to include('admin_body')

      get admin_path
      expect(response.body).to include('admin_password')
    end
  end
end
