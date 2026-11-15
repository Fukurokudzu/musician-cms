require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_date' do
    it 'uses the default DD.MM.YYYY format out of the box' do
      Setting.date_format = Setting::DEFAULT_DATE_FORMAT

      expect(helper.format_date(Date.new(2026, 12, 15))).to eq('15.12.2026')
    end

    it 'honours the configured format' do
      Setting.date_format = '%m/%d/%Y'

      expect(helper.format_date(Date.new(2026, 12, 15))).to eq('12/15/2026')
    end

    it 'supports the ISO format' do
      Setting.date_format = '%Y-%m-%d'

      expect(helper.format_date(Date.new(2026, 12, 15))).to eq('2026-12-15')
    end

    it 'returns nil when the given value is nil' do
      expect(helper.format_date(nil)).to be_nil
    end
  end

  describe '#format_datetime' do
    let(:time) { Time.zone.local(2026, 12, 15, 8, 5, 9) }

    it 'appends the time to the configured date format' do
      Setting.date_format = '%m/%d/%Y'

      expect(helper.format_datetime(time)).to eq('12/15/2026 08:05:09')
    end

    it 'returns nil when the given value is nil' do
      expect(helper.format_datetime(nil)).to be_nil
    end
  end

  describe '#date_format_options' do
    it 'offers every supported format with an example label' do
      options = helper.date_format_options

      expect(options.map(&:last)).to eq(Setting::DATE_FORMATS.keys)
      options.each do |label, format|
        expect(label).to include(described_class::DATE_FORMAT_EXAMPLE.strftime(format))
      end
    end
  end

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
