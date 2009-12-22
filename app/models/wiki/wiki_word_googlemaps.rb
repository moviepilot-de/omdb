module Wiki
  class WikiWordGooglemaps
    if not defined? WIKIWORD_GM_PATTERN
      WIKIWORD_GM_PATTERN = Regexp.new('\[\[[gG][mM]:([^:\|\]]*)\|?([^:\]]*)?\]\]')
    end

    def pattern
      WIKIWORD_GM_PATTERN
    end

    def to_o(match, object, lang)
      name, title = pattern.match(match).to_a.slice(1,2)
      href = "http://maps.google.com/?q=" + name
      content = title.empty? ? name : title
      "<a href=\"#{href}\" class=\"external\">#{content}</a>"
    end
  end
end
