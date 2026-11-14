module ReleasesHelper
  COVER_VARIANT_SIZE = [400, 400].freeze

  # Serves a downscaled variant of the cover to avoid shipping
  # full-sized originals to the page.
  def cover_image_tag(cover, size: COVER_VARIANT_SIZE, fetchpriority: nil, **options)
    image_options = {
      loading: options.delete(:loading) || 'lazy',
      decoding: options.delete(:decoding) || 'async',
      width: options.delete(:width) || size[0],
      height: options.delete(:height) || size[1]
    }
    image_options[:fetchpriority] = fetchpriority if fetchpriority.present?
    image_options.merge!(options)

    variant =
      case size
      when [400, 400]
        cover.variant(:card)
      when [200, 200]
        cover.variant(:thumb)
      when [1000, 1000]
        cover.variant(:detail)
      else
        cover.variant(resize_to_limit: size)
      end

    image_tag variant, **image_options
  rescue StandardError => e
    Rails.logger.warn "Cover variant failed, serving original: #{e.class}: #{e.message}"
    fallback_options = {
      loading: options[:loading] || 'lazy',
      decoding: options[:decoding] || 'async'
    }.merge(options)
    image_tag cover, **fallback_options
  end
end
