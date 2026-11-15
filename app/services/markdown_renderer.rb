# Renders Markdown to sanitized HTML with the same options everywhere
# (GitHub Flavored Markdown, like the SimpleMDE editor produces).
class MarkdownRenderer
  OPTIONS = {
    auto_ids: true,
    footnote_nr: 1,
    entity_output: :as_char,
    toc_levels: (1..6),
    smart_quotes: %w[lsquo rsquo ldquo rdquo],
    input: 'GFM',
    # GFM renders a single newline as <br> (like GitHub); without this the
    # editor inserts a line break that would silently vanish in the output.
    hard_wrap: true,
    enable_coderay: true,
    coderay_line_numbers: nil,
    coderay_css: :style,
    coderay_bold_every: 10,
    coderay_tab_width: 4
  }.freeze

  def self.call(text)
    return ''.html_safe if text.blank?

    sanitize_html(Kramdown::Document.new(text, OPTIONS).to_html)
  end

  # The markdown is authored by admins and rendered on public pages, so it
  # is run through the sanitizer instead of trusting raw HTML from kramdown.
  # The allow-list covers everything GFM produces; the sanitizer then checks
  # tag contents and inline CSS as well.
  ALLOWED_TAGS = Rails::HTML5::SafeListSanitizer.allowed_tags.to_a +
                 %w[table thead tbody tfoot tr th td caption].freeze
  ALLOWED_ATTRIBUTES = Rails::HTML5::SafeListSanitizer.allowed_attributes.to_a +
                       %w[id style].freeze

  def self.sanitize_html(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(html,
                                                 tags: ALLOWED_TAGS,
                                                 attributes: ALLOWED_ATTRIBUTES)
                                   .html_safe # rubocop:disable Rails/OutputSafety -- sanitizer output is trusted
  end
end
