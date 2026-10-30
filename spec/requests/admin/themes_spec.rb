require 'rails_helper'

RSpec.describe 'Admin::Themes', type: :request do
  let(:image_file) do
    fixture_file_upload(Rails.root.join('app/assets/images/korg.jpg'), 'image/jpeg')
  end

  before do
    post sessions_path, params: { admin_email: Setting.admin_email, admin_password: 'admin' }
  end

  describe 'PUT /admin/themes' do
    it 'updates theme colors' do
      put admin_themes_path, params: { setting: { accent_color: '#123456' } }

      expect(Setting.accent_color).to eq('#123456')
    end

    it 'attaches the uploaded background image' do
      put admin_themes_path, params: { setting: { background_image: image_file } }

      blob = ActiveStorage::Blob.find_signed(Setting.background_image)
      expect(blob).to be_present
      expect(blob.content_type).to eq('image/jpeg')
    end

    it 'replaces the previous background image' do
      put admin_themes_path, params: { setting: { background_image: image_file } }
      first_blob = ActiveStorage::Blob.find_signed(Setting.background_image)

      put admin_themes_path, params: { setting: { background_image: image_file } }

      expect(Setting.background_image).to be_present
      expect(ActiveStorage::Blob.find_signed(Setting.background_image)).not_to eq(first_blob)
    end

    it 'rejects non-image files' do
      file = fixture_file_upload(Rails.root.join('README.md'), 'text/plain')

      put admin_themes_path, params: { setting: { background_image: file } }

      expect(Setting.background_image).to be_blank
    end
  end

  describe 'DELETE /admin/themes' do
    it 'removes the background image' do
      put admin_themes_path, params: { setting: { background_image: image_file } }

      delete admin_themes_path

      expect(Setting.background_image).to be_blank
    end
  end

  describe 'GET /admin/themes' do
    it 'renders the theme tab without a background' do
      get admin_themes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Background image')
    end

    it 'renders the theme tab with a preview of the uploaded background' do
      put admin_themes_path, params: { setting: { background_image: image_file } }

      get admin_themes_path

      expect(response.body).to include('/rails/active_storage/blobs')
      expect(response.body).to include('Remove background')
    end
  end

  describe 'GET /themes/variables' do
    it 'falls back to the default background when none is set' do
      get themes_variables_path

      expect(response.media_type).to eq('text/css')
      expect(response.body).to include('background-image')
      expect(response.body).to include('korg')
    end

    it 'serves the uploaded background when set' do
      put admin_themes_path, params: { setting: { background_image: image_file } }

      get themes_variables_path

      expect(response.body).to include('/rails/active_storage/blobs')
    end

    it 'does not expose the background signed id as a css variable' do
      put admin_themes_path, params: { setting: { background_image: image_file } }

      get themes_variables_path

      expect(response.body).not_to include('--background-image')
    end
  end
end
