module Wiki
  class WikiWordMovie < WikiWord
    if not defined? WIKIWORD_MOVIE_PATTERN
      WIKIWORD_MOVIE_PATTERN = Regexp.new('\[\[[mM]:([0-9]+):?([^\]]*)?[^\]]*\]\]')
    end

    def pattern
      WIKIWORD_MOVIE_PATTERN
    end

    def to_o(match, object, lang)
      convert_to_object match, object, lang, :movie
    end
  end
end
