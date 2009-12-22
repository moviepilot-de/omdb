module Wiki
  class WikiWordCharacter < WikiWord
    if not defined? WIKIWORD_CHARACTER_PATTERN
      WIKIWORD_CHARACTER_PATTERN = Regexp.new('\[\[[cC][hH]:([0-9]+):?([^\]]*)?[^\]]*\]\]')
    end

    def pattern
      WIKIWORD_CHARACTER_PATTERN
    end

    def to_o(match, object, lang)
      convert_to_object match, object, lang, :character
    end
  end
end

