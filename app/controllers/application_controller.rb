class ApplicationController < ActionController::Base
  helper_method :admin?
  before_action :set_page_title, :set_track
  around_action :switch_locale

  def show_flash(type = :success, message)
    flash.now[type] = message
    render turbo_stream: turbo_stream.prepend('flash_toast', partial: 'layouts/flash_toast')
  end

  private

  def admin?
    session[:hashed_id] == Setting.admin_hashed_password
  end

  def switch_locale(&action)
    locale = if locale_set?
               Setting.locale
             elsif I18n.available_locales.map(&:to_s).include?(params[:locale])
               params[:locale] || I18n.default_locale
             else
               I18n.default_locale
             end

    I18n.with_locale(locale, &action)
  end

  def locale_set?
    I18n.available_locales.map(&:to_s).include?(Setting.locale)
  end

  def set_page_title
    @page_title = Setting.page_title
  end

  def set_track
    @track ||= Track.find_by(id: Rails.cache.read('current_track_id')) if Rails.cache.read('current_track_id').present?
    @track ||= Track.all.sample || Track.find_by(name: 'Default Track')

    @release = @track.release if @track.present?
  end

  def update_system_settings(checked_params)
    checked_params.each_key do |key|
      Setting.send("#{key}=", checked_params[key].strip) unless checked_params[key].nil?
    end
  end
end
