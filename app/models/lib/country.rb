module Globalize
  class Country
    include WikiEnabled
    include Statistics
    include LocalName
    include MovieListings
    include Logging
    
    db_depending_objects
    #depending_objects [ :self, :movies, :pages ]

    validates_presence_of :code, :name
    validates_uniqueness_of :code
    validates_format_of :code, :with => /^[a-zA-Z]{2}$/

    has_and_belongs_to_many :movies, 
                            :join_table => "movie_countries",
                            :select     => 'DISTINCT movies.*',
                            :order      => "movies.vote"

    has_and_belongs_to_many :chronological_movies, 
                            :class_name => "Movie",
                            :join_table => "movie_countries",
                            :conditions => "movies.end IS NOT NULL AND movies.end <= '#{Date.today.to_s}'",
                            :select     => 'DISTINCT movies.*',
                            :order      => "movies.end ASC"

    has_many :highest_rated_movies,
             :class_name => "Movie",
             :finder_sql => 'SELECT DISTINCT movies.* FROM movies
                               INNER JOIN movie_countries ON movies.id = movie_countries.movie_id
                             WHERE (movie_countries.country_id = #{id})
                             ORDER BY movies.vote DESC
                             LIMIT 25'

   has_many :popular_movies,
            :class_name => "Movie",
            :finder_sql => 'SELECT DISTINCT movies.* FROM movies
                              INNER JOIN movie_countries ON movies.id = movie_countries.movie_id
                            WHERE (movie_countries.country_id = #{id})
                              ORDER BY movies.popularity DESC
                            LIMIT 10'

    has_many :name_aliases, 
             :as => :related_object,
             :extend => LocalFinder,
             :dependent => true


    # localized summary text
    has_many :abstracts,
             :as        => :related_object,
             :extend    => LocalFinder,
             :dependent => true

    # localized wiki pages
    has_many :pages,
             :as        => :related_object,
             :extend    => LocalFinder,
             :order     => :name,
             :dependent => true

    has_one  :image,
             :as        => :related_object,
             :dependent => :destroy

    def self.[](symbol)
      self.find_by_code(symbol.to_s.upcase)
    end

    def all_movies( limit, offset )
      chronological_movies
    end

    def all_movies_paged( page = 1 )
      chronological_movies.find(:all, :page => { :current => page, :size => 24 } )
    end

    def Country.find_localized( q, lang )
      Searcher.search_countries( q, lang.code )
    end

    def self.search_by_prefix( q, lang, offset = 0, limit = 100 )
      Searcher.search_countries( q, lang.code, offset, limit )
    end
    
    def self.european_country_ids
      #these are the IDs for the european globalize countries
      #todo maybe check for a couple of to have the correct names just in case we'll someday update globalize
      #and it changes the country IDs - which it shouldn't do :) 
      country_list = Array.[](6,1,20,17,22,57,55,62,68,73,86,99,105,106,130,124,128,129,146,137,134,133,49,159,160,13,172,177,182,183,196,189,41,194,192,66,54,220,97,75,34)
      return country_list
    end
    
    def self.european_countries
      countries = Array.new
      self.european_country_ids.each {|id| countries.push(Country.find(id))}
    end
    
  end
end
