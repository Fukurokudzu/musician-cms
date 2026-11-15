class Admin::SystemsController < ApplicationController
  include AdminAuthorization

  def show
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("admin_body", partial: "system") }
      format.html { redirect_to admin_path }
    end
  end

  def update
    if update_system_settings(check_params)
      flash[:success] = t('admin.system.flash.updated', default: 'Settings updated')
      respond_to do |format|
        format.turbo_stream { redirect_to admin_path, status: :see_other }
        format.html { redirect_to admin_path, status: :see_other }
      end
    else
      flash.now[:error] = settings_error_message
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/flash"), status: :unprocessable_entity
    end
  end

  private

  def settings_error_message
    Array(@settings_errors).presence&.join(', ') ||
      t('admin.system.flash.error', default: 'Could not update settings')
  end

  def check_params
    params.require(:setting).permit(:admin_email, :admin_password, :description, :page_title, :timezone, :locale, :date_format, :library_path,
                                    :footer_link_type, :footer_email, :footer_subject, :footer_url)
  end
end
