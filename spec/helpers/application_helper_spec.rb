require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#custom_favicon_blob' do
    it 'returns nil when no favicon is configured' do
      Setting.favicon = ''

      expect(helper.custom_favicon_blob).to be_nil
    end

    it 'returns the blob for the stored signed id' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
        filename: 'favicon.svg',
        content_type: 'image/svg+xml'
      )
      Setting.favicon = blob.signed_id

      expect(helper.custom_favicon_blob).to eq(blob)
    end

    it 'returns nil for a tampered signed id' do
      Setting.favicon = 'definitely-not-a-signed-id'

      expect(helper.custom_favicon_blob).to be_nil
    end

    it 'returns nil when the referenced blob no longer exists' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('icon'), filename: 'favicon.png', content_type: 'image/png'
      )
      signed_id = blob.signed_id
      blob.purge
      Setting.favicon = signed_id

      expect(helper.custom_favicon_blob).to be_nil
    end
  end
end
