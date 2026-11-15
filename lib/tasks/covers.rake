# frozen_string_literal: true

namespace :covers do
  desc 'Enqueue ActiveStorage::TransformJob for every preprocessed named cover variant ' \
       '(WebP). Idempotent: variants that already exist on disk are left alone.'
  task preprocess: :environment do
    enqueued = 0
    # Named variants are defined on the attachment reflection (see the
    # `has_one_attached :cover do |attachable| ... end` block in Release).
    # ActiveStorage::Attachment#named_variants is private, so go through the
    # public reflection API instead: Release.reflect_on_attachment(:cover).
    named_variants = Release.reflect_on_attachment(:cover).named_variants

    # config.load_defaults enables ActiveStorage.track_variants, so a variant's
    # existence is the presence of an active_storage_variant_records row keyed by
    # the variation digest — not a path on disk (VariantWithRecord#key is nil
    # until the first processing creates the record). Compute the digest the
    # same way ActiveStorage does, via the variant object itself.
    Release.includes(cover_attachment: :blob).find_each do |release|
      next unless release.cover.attached?

      blob = release.cover.blob

      named_variants.each_value do |named_variant|
        next unless named_variant.preprocessed?(release)

        begin
          variant = blob.variant(named_variant.transformations)
        rescue ActiveStorage::InvariableError
          warn "Skipping release ID=#{release.id}: cover is not a transformable image"
          next
        end

        next if blob.variant_records.exists?(variation_digest: variant.variation.digest)

        ActiveStorage::TransformJob.perform_later(blob, named_variant.transformations)
        enqueued += 1
      end
    end

    puts "Enqueued #{enqueued} variant transform job(s) (processed by Sidekiq)"
  end
end
