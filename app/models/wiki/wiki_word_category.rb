module Wiki
  class WikiWordCategory < WikiWord
    if not defined? WIKIWORD_CATEGORY_PATTERN
      WIKIWORD_CATEGORY_PATTERN = Regexp.new('\[\[[Cc][Aa]:([0-9]+):?([^\]]*)?[^\]]*\]\]')
    end

    def pattern
      WIKIWORD_CATEGORY_PATTERN
    end

    def to_o(match, object, lang)
      convert_to_object match, object, lang, :category
    end
  end
end

