module ReleasesHelper
  COVER_VARIANT_SIZE = [400, 400].freeze

  # Serves a downscaled variant of the cover to avoid shipping
  # full-sized originals to the main page.
  def cover_image_tag(cover, size: COVER_VARIANT_SIZE, **options)
    image_tag cover.variant(resize_to_limit: size), loading: 'lazy', **options
  rescue StandardError => e
    Rails.logger.warn "Cover variant failed, serving original: #{e.class}: #{e.message}"
    image_tag cover, loading: 'lazy', **options
  end
end
