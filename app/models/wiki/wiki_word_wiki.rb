module Wiki
  class WikiWordWiki
    if not defined? WIKIWORD_WIKI_PATTERN
      WIKIWORD_WIKI_PATTERN = Regexp.new('\[\[([^!][^\|\]]*)\|?([^:\]]*)?\]\]')
    end

    def pattern
      WIKIWORD_WIKI_PATTERN
    end

    # Eingabe im Format [[TargetPage|Darzustellender Titel]]
    def to_o(match, object, lang)
      name, title = pattern.match(match).to_a.slice(1,2)
      if object
        object.page(name, lang, title.blank? ? name : title)
      else
        returning result = (Page.generic_page_for_language(name, lang) || 
                            Page.new(:page_name => name, :language => lang, :name => name)) do
          result.display_title = title if title
        end
      end
    end
  end
end
