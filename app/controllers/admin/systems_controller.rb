class Admin::SystemsController < ApplicationController
  def show
    render turbo_stream: turbo_stream.update("admin_body", partial: "system")
  end

  def update
    if update_system_settings(check_params)
      #FIXME translation
      flash.now[:success] = "Settings updated"
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/flash")
    end
  end

  private

  def check_params
    params.require(:setting).permit(:admin_email, :description, :page_title, :timezone, :locale, :library_path)
  end
end
