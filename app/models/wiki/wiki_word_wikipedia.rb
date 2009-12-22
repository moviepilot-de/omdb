module Wiki
  class WikiWordWikipedia
    if not defined? WIKIWORD_WIKIPEDIA_PATTERN
      WIKIWORD_WIKIPEDIA_PATTERN = Regexp.new('\[\[[wW][pP]:([^:\|\]]*)\|?([^:\]]*)?\]\]')
    end

    def pattern
      WIKIWORD_WIKIPEDIA_PATTERN
    end

    def to_o(match, object, lang)
      name, title = pattern.match(match).to_a.slice(1,2)
      href = "http://" + lang.code + ".wikipedia.org/wiki/" + name
      content = title.empty? ? name : title
      "<a href=\"#{href}\" class=\"external\">#{content}</a>"
    end
  end
end
