module Globalize
  class Language
    has_many :contents
    has_many :castComments
    has_many :releases
    has_many :category_aliases

    has_and_belongs_to_many :movies, :join_table => "movie_languages"

    def name
      self.english_name
    end

    def code
      self.iso_639_1
    end

    def alias_names_by_language
      aliases = {}
      LOCALES.each_key { |key|
        aliases[Language.pick(key)] = [ Locale.translator.fetch( self.name, Language.pick(key) ) ]
      }
      aliases
    end
    
    def local_name( lang = Locale.base_language )
      Locale.translator.fetch( self.name, Language.pick( lang.code ) )
    end
    
    def Language.find_localized( q, lang )
      Searcher.search_languages( q, lang.code )
    end
    
    def self.find_by_prefix( q, lang, offset = 0, limit = 40 )
      Searcher.search_languages( q, lang.code )
    end
    
    def Language.independent_language
      Language.find(1)
    end
    
  end
end
