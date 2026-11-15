class Admin::ThemesController < ApplicationController
  include AdminAuthorization

  def show
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'system') }
      format.html { redirect_to admin_path }
    end
  end

  def update
    background = params[:setting]&.dig(:background_image)
    favicon = params[:setting]&.dig(:favicon)

    if update_system_settings(check_params)
      attach_background!(background) if background.present?
      attach_favicon!(favicon) if favicon.present?
      Setting.clear_cache if Setting.respond_to?(:clear_cache)
      flash.now[:success] = t('admin.theme.flash.updated')
    else
      flash.now[:error] = Array(@settings_errors).presence&.join(', ') ||
                          t('admin.system.flash.error', default: 'Could not update settings')
    end

    render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash')
  end

  def destroy
    if params[:target] == 'favicon'
      purge_favicon!
      flash.now[:success] = t('admin.theme.flash.favicon_removed')
    else
      purge_background!
      flash.now[:success] = t('admin.theme.flash.background_removed')
    end
    Setting.clear_cache if Setting.respond_to?(:clear_cache)

    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'system'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end

  private

  def check_params
    params.require(:setting).permit(:artist_title_color, :text_color, :main_menu_bg_color, :footer_bg_color,
                                    :player_bg_color, :accent_color, :a_color, :a_hover_color, :border_radius)
  end

  def attach_background!(file)
    unless file.content_type.to_s.start_with?('image/')
      flash.now[:error] = 'Background must be an image file'
      return
    end

    purge_background!

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file.tempfile,
      filename: file.original_filename,
      content_type: file.content_type
    )
    Setting.background_image = blob.signed_id
  end

  def purge_background!
    ActiveStorage::Blob.find_signed(Setting.background_image.presence)&.purge
    Setting.background_image = ''
  end

  def attach_favicon!(file)
    content_type = file.content_type.to_s
    unless content_type.match?(%r{image/(png|jpeg|jpg|x-icon|vnd\.microsoft\.icon|svg\+xml|webp)})
      flash.now[:error] = t('admin.theme.flash.favicon_invalid', default: 'Favicon must be an image file (PNG, JPG, ICO, SVG or WebP)')
      return
    end

    purge_favicon!

    io, filename, upload_content_type = processed_favicon_upload(file, content_type)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: io,
      filename: filename,
      content_type: upload_content_type
    )
    Setting.favicon = blob.signed_id
  ensure
    io.close! if io.respond_to?(:close!) && io != file.tempfile
  end

  def processed_favicon_upload(file, content_type)
    if content_type.match?(%r{image/(svg\+xml|x-icon|vnd\.microsoft\.icon)})
      [file.tempfile, file.original_filename, content_type]
    else
      processed = ImageProcessing::Vips
                    .source(file.tempfile)
                    .resize_to_limit(512, 512)
                    .call
      [processed, file.original_filename, content_type]
    end
  rescue LoadError, StandardError => e
    Rails.logger.warn("Favicon processing failed, using original: #{e.class}: #{e.message}")
    [file.tempfile, file.original_filename, content_type]
  end

  def purge_favicon!
    signed_id = Setting.favicon.presence
    blob = ActiveStorage::Blob.find_signed(signed_id) if signed_id
    blob&.purge_later
    Setting.favicon = ''
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    Setting.favicon = ''
  end
end
