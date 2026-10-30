class Admin::ThemesController < ApplicationController
  include AdminAuthorization

  def show
    render turbo_stream: turbo_stream.update('admin_body', partial: 'system')
  end

  def update
    background = params[:setting]&.dig(:background_image)

    if update_system_settings(check_params)
      attach_background!(background) if background.present?
      #FIXME translation
      flash.now[:success] = 'Settings updated'
    end

    render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash')
  end

  def destroy
    purge_background!
    #FIXME translation
    flash.now[:success] = 'Background image removed'

    render turbo_stream: [
      turbo_stream.update('admin_body', partial: 'system'),
      turbo_stream.update('flash', partial: 'layouts/flash')
    ]
  end

  private

  def check_params
    params.require(:setting).permit(:artist_title_color, :text_color, :main_menu_bg_color, :footer_bg_color,
                                    :player_bg_color, :accent_color, :a_color, :a_hover_color)
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
end
