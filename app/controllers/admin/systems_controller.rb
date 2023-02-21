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
    params.require(:setting).permit(:admin_email, :description, :app_name, :timezone, :locale) 
  end

  def update_system_settings(checked_params)
    checked_params.keys.each do |key|
      Setting.send("#{key}=", checked_params[key].strip) unless checked_params[key].nil?
    end
  end
end
