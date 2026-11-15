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

    it 'picks the named variant matching the requested size' do
      expect(release.cover).to receive(:variant).with(:card).and_call_original
      expect(release.cover).to receive(:variant).with(:thumb).and_call_original
      expect(release.cover).to receive(:variant).with(:detail).and_call_original

      helper.cover_image_tag(release.cover, size: [400, 400])
      helper.cover_image_tag(release.cover, size: [200, 200])
      helper.cover_image_tag(release.cover, size: [1000, 1000])
    end

    it 'resizes to any other size without a named variant' do
      expect(release.cover).to receive(:variant).with(resize_to_limit: [120, 80]).and_call_original

      html = helper.cover_image_tag(release.cover, size: [120, 80])

      expect(html).to include('width="120"')
      expect(html).to include('height="80"')
      expect(html).to include('active_storage/representations')
    end

    it 'passes eager loading and priorities through to the image tag' do
      html = helper.cover_image_tag(release.cover, loading: 'eager', fetchpriority: 'high', alt: 'Cover')

      expect(html).to include('loading="eager"')
      expect(html).to include('fetchpriority="high"')
      expect(html).to include('alt="Cover"')
      expect(html).to include('decoding="async"')
    end
  end
end
