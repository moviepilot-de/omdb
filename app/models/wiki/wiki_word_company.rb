module Wiki
  class WikiWordCompany < WikiWord
    if not defined? WIKIWORD_COMPANY_PATTERN
      WIKIWORD_COMPANY_PATTERN = Regexp.new('\[\[[cC][oO]:([0-9]+):?([^\]]*)?[^\]]*\]\]')
    end

    def pattern
      WIKIWORD_COMPANY_PATTERN
    end

    def to_o(match, object, lang)
      convert_to_object match, object, lang, :company
    end
  end
end

