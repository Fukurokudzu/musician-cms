require 'rails_helper'

RSpec.describe ReleasesHelper, type: :helper do
  describe '#cover_image_tag' do
    let(:release) { create(:release, artist: create(:artist)) }

    before do
      release.cover.attach(
        io: File.open(Rails.root.join('app/assets/images/korg.jpg')),
        filename: 'korg.jpg',
        content_type: 'image/jpeg'
      )
    end

    it 'renders a lazy loaded downscaled variant' do
      html = helper.cover_image_tag(release.cover, class: 'cover')

      expect(html).to include('active_storage/representations')
      expect(html).to include('loading="lazy"')
      expect(html).to include('class="cover"')
    end

    it 'falls back to the original file when the variant cannot be built' do
      allow(release.cover).to receive(:variant).and_raise(StandardError, 'variant unavailable')

      html = helper.cover_image_tag(release.cover, class: 'cover')

      expect(html).not_to include('active_storage/representations')
      expect(html).to include('loading="lazy"')
    end
  end
end
