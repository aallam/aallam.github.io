# frozen_string_literal: true

module Jekyll
  module InlineCodeBreaksFilter
    # Allow inline identifiers to wrap after punctuation without changing copied text.
    def inline_code_breaks(html)
      html.gsub(/<pre\b[^>]*>.*?<\/pre>|(<code\b[^>]*>)([^<]*)(<\/code>)/mi) do |element|
        opening, text, closing = Regexp.last_match.captures
        next element unless opening

        wrapped = text.gsub(/(?:[.\/]|::)(?=[[:alpha:]_$])/, '\0<wbr>')
        "#{opening}#{wrapped}#{closing}"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::InlineCodeBreaksFilter)
