module ApplicationHelper
  DATE_FORMAT_EXAMPLE = Date.new(2026, 12, 15)

  # Formats a Date/Time using the format from Setting.date_format, falling
  # back to the default when the stored value is missing or not supported.
  def format_date(date)
    date&.strftime(configured_date_format)
  end

  def format_datetime(time)
    time&.strftime("#{configured_date_format} %H:%M:%S")
  end

  # [label, value] pairs for the date format select in the admin settings form,
  # e.g. ["15.12.2026 (DD.MM.YYYY)", "%d.%m.%Y"].
  def date_format_options
    Setting::DATE_FORMATS.map { |fmt, label| ["#{DATE_FORMAT_EXAMPLE.strftime(fmt)} (#{label})", fmt] }
  end

  # [label, value] pairs for the site locale select in the admin settings
  # form, e.g. ["Español", "es"]. Falls back to the raw code for locales
  # without a name listed here.
  LANGUAGE_NAMES = {
    'en' => 'English',
    'ru' => 'Русский',
    'es' => 'Español',
    'fr' => 'Français',
    'de' => 'Deutsch'
  }.freeze

  def locale_options
    I18n.available_locales.map(&:to_s).map { |code| [LANGUAGE_NAMES.fetch(code, code), code] }
  end

  # Signed blob of the custom favicon from settings, or nil when unset/invalid.
  def custom_favicon_blob
    return nil if Setting.favicon.blank?

    ActiveStorage::Blob.find_signed(Setting.favicon)
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  private

  def configured_date_format
    format = Setting.date_format
    Setting::DATE_FORMATS.key?(format) ? format : Setting::DEFAULT_DATE_FORMAT
  end
end
