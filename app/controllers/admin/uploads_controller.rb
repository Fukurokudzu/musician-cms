module Admin
  class UploadsController < ApplicationController
    include AdminAuthorization

    MAX_SIZE = 10.megabytes
    ALLOWED_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
    ALLOWED_EXTENSIONS = %w[png jpg jpeg gif webp].freeze

    # Stores a single image as an Active Storage blob and returns its public
    # (signed) URL as JSON, so the markdown editor can insert it into the
    # document. Used by the md-editor Stimulus controller for all SimpleMDE
    # fields in the admin area.
    def create
      file = params[:file].presence || params[:image]
      return render json: { error: t('admin.uploads.missing_file') }, status: :unprocessable_entity if file.blank?

      extension = File.extname(file.original_filename.to_s).delete('.').downcase
      unless ALLOWED_TYPES.include?(file.content_type) && ALLOWED_EXTENSIONS.include?(extension)
        return render json: { error: t('admin.uploads.invalid_type') }, status: :unprocessable_entity
      end

      if file.size > MAX_SIZE
        return render json: { error: t('admin.uploads.too_big', size: helpers.number_to_human_size(MAX_SIZE)) },
                      status: :unprocessable_entity
      end

      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: sanitized_filename(file.original_filename),
                                                    content_type: file.content_type)
      AuditLogger.log(action: 'upload.image', request:,
                      metadata: { filename: file.original_filename, bytes: file.size })
      render json: { url: url_for(blob) }
    rescue StandardError => e
      Rails.logger.error("Image upload failed: #{e.class}: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def sanitized_filename(name)
      base = File.basename(name.to_s).gsub(/[^\w.-]+/, '_').gsub(/\A\.+/, '')
      base.presence || 'image.png'
    end
  end
end
