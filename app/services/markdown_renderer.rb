# Renders Markdown to sanitized-ish HTML with the same options everywhere
# (GitHub Flavored Markdown, like the SimpleMDE editor produces).
class MarkdownRenderer
  OPTIONS = {
    auto_ids: true,
    footnote_nr: 1,
    entity_output: :as_char,
    toc_levels: (1..6),
    smart_quotes: ['lsquo', 'rsquo', 'ldquo', 'rdquo'],
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

    Kramdown::Document.new(text, OPTIONS).to_html.html_safe
  end
end
