# frozen_string_literal: true

namespace :covers do
  desc "Enqueue ActiveStorage::TransformJob for every preprocessed named cover variant " \
       "(WebP). Idempotent: variants that already exist on disk are left alone."
  task preprocess: :environment do
    enqueued = 0
    # Named variants are defined on the attachment reflection (see the
    # `has_one_attached :cover do |attachable| ... end` block in Release).
    # ActiveStorage::Attachment#named_variants is private, so go through the
    # public reflection API instead: Release.reflect_on_attachment(:cover).
    named_variants = Release.reflect_on_attachment(:cover).named_variants

    Release.includes(cover_attachment: :blob).find_each do |release|
      next unless release.cover.attached?

      named_variants.each_value do |named_variant|
        next unless named_variant.preprocessed?(release)

        blob = release.cover.blob
        # Key only, no .processed — checking existence must not trigger an
        # inline re-encode. Variant keys embed the transformation digest, so
        # WebP variants absent on disk simply get enqueued.
        next if blob.service.exist?(blob.variant(named_variant.transformations).key)

        ActiveStorage::TransformJob.perform_later(blob, named_variant.transformations)
        enqueued += 1
      end
    end

    puts "Enqueued #{enqueued} variant transform job(s) (processed by Sidekiq)"
  end
end
