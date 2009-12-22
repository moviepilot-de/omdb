module Wiki
  class EscapedWikiWord < WikiWord

    ESCAPED_WIKIWORD_PATTERN = Regexp.new('\[\[!.+\]\]')

    def pattern
      ESCAPED_WIKIWORD_PATTERN
    end

    def to_o(match, object, lang)
      match.gsub '!', ''
    end
  end
end

