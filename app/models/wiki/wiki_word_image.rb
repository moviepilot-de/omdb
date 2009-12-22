module Wiki
  class WikiWordImage < WikiWord
    if not defined? WIKIWORD_IMAGE_PATTERN
      WIKIWORD_IMAGE_PATTERN = Regexp.new('\[\[[iI]:([0-9]+)([^\]]*)?\]\]')
    end

    def pattern
      WIKIWORD_IMAGE_PATTERN
    end

    def to_o(match, object, lang)
      convert_to_object match, object, lang, :image
    end
  end
end
