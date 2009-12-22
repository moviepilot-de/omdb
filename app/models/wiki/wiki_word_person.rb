module Wiki
  class WikiWordPerson < WikiWord
    if not defined? WIKIWORD_PERSON_PATTERN
      WIKIWORD_PERSON_PATTERN = Regexp.new('\[\[[pP]:([0-9]+):?([^\]]*)?[^\]]*\]\]')
    end

    def pattern
      WIKIWORD_PERSON_PATTERN
    end

    def to_o(match, object, lang)
      convert_to_object match, object, lang, :person
    end
  end
end

