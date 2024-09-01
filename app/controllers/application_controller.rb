class ApplicationController < ActionController::Base

  around_action :switch_locale

  def show_flash(type = :success, message)
    flash.now[type] = message
    render turbo_stream: turbo_stream.prepend("flash_toast", partial: "layouts/flash_toast")
  end

  private

  def switch_locale(&action)

    if locale_set?
      locale = Setting.locale
    elsif I18n.available_locales.map(&:to_s).include?(params[:locale])
      locale = params[:locale] || I18n.default_locale
    else
      locale = I18n.default_locale
    end
    
    I18n.with_locale(locale, &action)
  end

  def locale_set?
    I18n.available_locales.map(&:to_s).include?(Setting.locale)
  end
  
end
