class Company < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include Statistics
  include MovieListings
  include TreeStructure
  include Logging
  
  freezable_attribute :name
  freezable_attribute :parent

  db_depending_objects
  #depending_objects [ :self, :movies ]

  acts_as_tree :order => 'name'

  has_many :name_aliases, :as => :related_object
  
  has_many :trailers

  has_many :movies,
           :through => :production_companies,
           :order   => 'end'

  has_many :blockbuster,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies
                             INNER JOIN production_companies ON production_companies.movie_id = movies.id
                           WHERE
                             (production_companies.company_id = #{id}) ORDER BY revenue DESC
                           LIMIT 25'

  has_many :chronological_movies, 
           :class_name => "Movie",
           :through    => :production_companies,
           :source     => :movie,
           :select     => 'DISTINCT movies.*',
           :conditions => "movies.end IS NOT NULL",
           :order      => "movies.end ASC"

  has_many :highest_rated_movies,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies 
                             INNER JOIN production_companies ON movies.id = production_companies.movie_id 
                           WHERE 
                             (production_companies.company_id = #{id}) ORDER BY movies.vote DESC 
                           LIMIT 25'

  has_many :popular_movies,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies 
                             INNER JOIN production_companies ON movies.id = production_companies.movie_id 
                           WHERE 
                             (production_companies.company_id = #{id}) ORDER BY movies.popularity DESC
                           LIMIT 10'


  has_many :production_companies,
           :dependent  => :destroy

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
  alias :logo :image

  alias :ordered_children :children
  
  def aliases
    name_aliases
  end

  def all_children
    self.children + self.children.collect { |c| c.all_children }.delete_if { |c| c == [] }.flatten
  end

  def all_movies( limit, offset )
    movies.slice( offset, limit )
  end
  
  def all_movies_paged( page = 1 )
    Movie.find(:all, :page => { :size => 24, :current => page, :count => all_movie_count },
       :select     => "DISTINCT movies.*",
       :joins      => "INNER JOIN production_companies as prod on movies.id = prod.movie_id",
       :conditions => "prod.company_id in (#{all_children.push(self).collect{|c| c.id }.join(",")}) and movies.end is not null",
       :order      => "movies.end")
  end
  
  def all_movie_count
    result = connection.select_one("select (select count(distinct movies.id) from movies inner join production_companies as prod on movies.id = prod.movie_id and prod.company_id in (#{all_children.push(self).collect{|c| c.id }.join(",")}) and movies.end is not null) as movie_count")
    result["movie_count"].to_i
  end
  
  def self.popular
    Company.find(:all, 
               :limit => 10,
               :order => "popularity DESC")
  end
  
  def self.highest_rated
    Company.find(:all, 
               :limit => 10,
               :order => "vote DESC")
  end

  def self.recently_added
    Company.find(:all, 
               :limit => 10,
               :order => "created_at DESC")
  end  

  def self.search( filter, language = Locale.base_language )
    Searcher.search_companies_by_prefix( filter, language.code )
  end

  def self.search_by_prefix( filter )
    Searcher.search_companies_by_prefix( filter )
  end

  def self.find_orphans
    Company.find_by_sql( "SELECT companies.*, production_companies.id as pc_id FROM companies LEFT JOIN 
         production_companies ON companies.id = production_companies.company_id WHERE ISNULL(production_companies.id)" )
  end
end
