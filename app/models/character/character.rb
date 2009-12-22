class Character < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include LocalName
  include Logging

  freezable_attribute :name

  depending_objects [ :self, :movies, :people, :pages ]

  has_many :name_aliases,
           :as        => :related_object,
           :extend    => LocalFinder, 
           :dependent => true

  has_many :casts,
           :include => [ :movie, :person ],
           :order => 'movies.end DESC'

  has_many :people, 
           :through => :casts,
           :order => 'people.popularity DESC'

  has_many :movies,
           :through => :casts,
           :order => 'movies.end'

  # localized summary text
  has_many :abstracts,
           :as        => :related_object,
           :extend    => LocalFinder,
           :dependent => true

  # localized wiki pages
  has_many :pages,
           :as        => :related_object,
           :order     => :name,
           :extend    => LocalFinder,
           :dependent => true

  # Even though it is just one movie, we need to go with has_many, as has_one 
  # doesn't support an finder_sql parameter.
  has_many :first_movie,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies
                             INNER JOIN casts ON movies.id = casts.movie_id
                           WHERE
                             (casts.character_id = #{id}) ORDER BY movies.end ASC
                           LIMIT 1'

  has_many :top_movies,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies
                             INNER JOIN casts ON movies.id = casts.movie_id
                           WHERE
                             (casts.character_id = #{id}) ORDER BY movies.popularity DESC
                           LIMIT 5'
                    
  has_one  :image,
           :as        => :related_object,
           :dependent => :destroy
  alias :portrait :image
         
  validates_presence_of :name

  if not defined? FIND_CHARACTER_SQL_CONDITION
    FIND_CHARACTER_SQL_CONDITION = "LOWER(characters.name) like ?"
  end

  def all_movies_paged( page = 1 )
    movies.find(:all, :page => { :current => page, :size => 24 } )
  end
  
  def assoc_column_name
    Inflector.singularize(self.class.table_name) + "_id"
  end

  def superclass
    Character
  end
  
  def aliases
    name_aliases
  end
  
  def local_aliases( lang )
    aliases.local( lang )
  end
  
  def name
    self.attributes["name"]
  end
  
  def Character.search( query, lang )
    Searcher.search_characters( query, lang.code )
  end
  
  def to_search_result_xml( xml, language = Locale.base_language )
    xml.character do
      xml.id self.id
      xml.name self.name
      xml.abstract self.abstracts.local(language).first.nil? ? "" : self.abstracts.local( language ).first.data
    end
  end
  

end
