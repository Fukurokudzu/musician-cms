require 'rails_helper'

RSpec.describe 'Admin::Systems', type: :request do
  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe 'GET /admin/system' do
    it 'renders the system settings tab' do
      get admin_system_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Security')
    end
  end

  describe 'PATCH /admin/system' do
    it 'updates general settings' do
      patch admin_system_path,
            params: { setting: { page_title: 'My Music', description: 'Site desc', locale: 'en' } },
            as: :turbo_stream

      expect(response).to have_http_status(:see_other)
      expect(Setting.page_title).to eq('My Music')
      expect(Setting.description).to eq('Site desc')
    end

    it 'stores the chosen locale' do
      patch admin_system_path, params: { setting: { locale: 'ru' } }, as: :turbo_stream

      expect(response).to have_http_status(:see_other)
      expect(Setting.locale).to eq('ru')
    end

    it 'stores the chosen date format' do
      patch admin_system_path, params: { setting: { date_format: '%m/%d/%Y' } }, as: :turbo_stream

      expect(response).to have_http_status(:see_other)
      expect(Setting.date_format).to eq('%m/%d/%Y')
    end

    it 'rejects an unsupported date format with 422 and leaves the stored value intact' do
      previous = Setting.date_format

      expect do
        patch admin_system_path, params: { setting: { date_format: 'bogus' } }, as: :turbo_stream
      end.not_to raise_error

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Setting.date_format).to eq(previous)
    end

    it 'changes the admin password and locks the current session out' do
      previous_hash = Setting.admin_hashed_password

      patch admin_system_path, params: { setting: { admin_password: 'brand_new_password' } }, as: :turbo_stream

      expect(response).to have_http_status(:see_other)
      expect(Setting.admin_hashed_password).not_to eq(previous_hash)
      expect(Auth.new(Setting.admin_email, 'admin').hashed_id).to be_nil
      expect(Auth.new(Setting.admin_email, 'brand_new_password').hashed_id).to be_present

      get admin_path
      expect(response.body).to include('admin_password')
    end

    it 'keeps the current password when the field is left blank' do
      patch admin_system_path, params: { setting: { page_title: 'Still My Music' } }, as: :turbo_stream

      expect(Auth.new(Setting.admin_email, 'admin').hashed_id).to be_present
      expect(Setting.page_title).to eq('Still My Music')
    end

    it 'rejects an invalid value with 422 and a message instead of raising' do
      expect do
        patch admin_system_path,
              params: { setting: { description: 'must roll back', page_title: 'x' } },
              as: :turbo_stream
      end.not_to raise_error

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Page title is too short')
      expect(response.body).not_to include('translation_missing')
    end

    it 'rolls the whole settings update back when one value is invalid' do
      patch admin_system_path,
            params: { setting: { description: 'must roll back', page_title: 'x' } },
            as: :turbo_stream

      # The description is written before the page title, and must not survive
      # the failed update.
      expect(Setting.description).not_to eq('must roll back')
      expect(Setting.page_title).not_to eq('x')
      expect(Setting.description).to be_present
    end
  end
end
