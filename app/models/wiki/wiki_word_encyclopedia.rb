module Wiki
  class WikiWordEncyclopedia
    if not defined? WIKIWORD_PERSON_PATTERN
      WIKIWORD_ENCYCLOPEDIA_PATTERN = Regexp.new('\[\[[eE]:([^\]\|]+)\|?([^\]]*)?[^\]]*\]\]')
    end

    def pattern
      WIKIWORD_ENCYCLOPEDIA_PATTERN
    end

    def to_o(match, object, lang)
      id, title = pattern.match(match).to_a.slice(1,2)
      page = EncyclopediaPage.find_by_name_and_language_id(id, @language)
      if page.nil?
        page = EncyclopediaPage.new
        page.name = id
        page.display_title = title.empty? ? id : title
      end
      page
    end
  end
end

