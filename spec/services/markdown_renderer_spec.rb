require 'rails_helper'

RSpec.describe MarkdownRenderer do
  describe '.call' do
    it 'returns an empty html safe string for blank input' do
      [nil, '', '   '].each do |blank|
        result = described_class.call(blank)

        expect(result).to eq('')
        expect(result).to be_html_safe
      end
    end

    it 'returns html safe output' do
      expect(described_class.call('# Hello')).to be_html_safe
    end

    it 'renders headings with anchors, emphasis and links' do
      html = described_class.call("# My Title\n\nSome **bold** and *italic* [text](https://example.com)\n")

      expect(html).to include('<h1 id="my-title">')
      expect(html).to include('<strong>bold</strong>')
      expect(html).to include('<em>italic</em>')
      expect(html).to include('<a href="https://example.com">text</a>')
    end

    it 'renders github flavored tables' do
      html = described_class.call("| left | right |\n| --- | --- |\n| 1 | 2 |\n")

      expect(html).to include('<table>')
      expect(html).to include('<td>1</td>')
    end

    it 'renders fenced code blocks with syntax highlighting' do
      html = described_class.call("```ruby\nputs 'hi'\n```\n")

      expect(html).to include('<code')
      expect(html).to include('puts')
    end

    it 'renders single newlines as <br> like GitHub (hard_wrap is on)' do
      html = described_class.call("line one\nline two\n")

      expect(html).to include('line one')
      expect(html).to include('<br>')
    end
  end
end
