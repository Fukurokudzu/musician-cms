module ReleasesHelper
  COVER_VARIANT_SIZE = [400, 400].freeze
  NAMED_VARIANTS = {
    [200, 200] => :thumb,
    [400, 400] => :card,
    [500, 500] => :medium,
    [1000, 1000] => :detail
  }.freeze

  # Serves a downscaled variant of the cover to avoid shipping
  # full-sized originals to the page.
  def cover_image_tag(cover, size: COVER_VARIANT_SIZE, fetchpriority: nil, srcset_sizes: nil, sizes: nil, **options)
    image_options = {
      loading: options.delete(:loading) || 'lazy',
      decoding: options.delete(:decoding) || 'async',
      width: options.delete(:width) || size[0],
      height: options.delete(:height) || size[1]
    }
    image_options[:fetchpriority] = fetchpriority if fetchpriority.present?
    image_options[:sizes] = sizes if sizes.present?
    image_options[:srcset] = build_srcset(cover, srcset_sizes) if srcset_sizes.present?
    image_options.merge!(options)

    image_tag variant_for(cover, size), **image_options
  rescue StandardError => e
    Rails.logger.warn "Cover variant failed, serving original: #{e.class}: #{e.message}"
    fallback_options = {
      loading: options[:loading] || 'lazy',
      decoding: options[:decoding] || 'async'
    }.merge(options)
    image_tag cover, **fallback_options
  end

  private

  def variant_for(cover, size)
    named_variant = NAMED_VARIANTS[size]
    return cover.variant(named_variant) if named_variant

    cover.variant(resize_to_limit: size, format: :webp, saver: { quality: 90, strip: true })
  end

  def build_srcset(cover, sizes)
    sizes.map { |width| "#{url_for(variant_for(cover, [width, width]))} #{width}w" }.join(', ')
  end
end
