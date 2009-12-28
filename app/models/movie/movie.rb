# Copyright (c) 2006 Benjamin Krause
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# = Movie
#
# This is the basic movie-model. This model used the 'Single Table 
# Inheritance' feature of rails and is divided into the following subtypes:
# 
# * MovieSeries (series of movies like Batman, Star Wars or X-Files (1 series and 1 movie))
# * Movie (plain and simple, a movie)
# * Series (series like The Simpsons or X-Files (TV Series))
# * Season (a single season within the series)
# * Episode (a single episode within a season)
#
# Each of these subtypes implement different possible actions.

class Movie < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include TreeStructure
  include LocalName
  include Statistics
  include Logging
  include TrackBackable

  class_inheritable_accessor :stub_fields

  freezable_attribute :self
  freezable_attribute :parent
  freezable_attribute :name
  freezable_attribute :homepage
  freezable_attribute :status
  freezable_attribute :type
  freezable_attribute :runtime
  freezable_attribute :end
  freezable_attribute :budget
  freezable_attribute :revenue
  freezable_attribute :languages
  freezable_attribute :countries
  freezable_attribute :companies
  freezable_attribute :references
  freezable_attribute :inherit_cast
  freezable_attribute :series_type
  
  db_depending_objects
  
  disable_logging_of :vote, :votes_count
  
  stub [ :end ]
  stub [ :casts, :crew, :genres, :plot_keywords, :languages ], :if => :empty?
  stub [ :runtime ], :if => Proc.new { |value| value == 0 }

  # Set the valid Status Types of a Movie. These types are valid for all
  # subclasses.
  if not defined? VALID_STATUS_TYPES
    VALID_STATUS_TYPES = [ "Rumored", "Planned", "In Production", "Released", "Canceled" ]
  end

  # localized movie titles
  has_many :name_aliases, 
           :as        => :related_object,
           :order     => :name,
           :extend    => LocalFinder,
           :dependent => :destroy

  # localized wiki pages
  has_many :pages,
           :as        => :related_object,
           :extend    => LocalFinder,
           :order     => :name,
           :dependent => :destroy
 
  # localized summary text
  has_many :abstracts,
           :as        => :related_object,
           :extend    => LocalFinder,
           :dependent => :destroy

  # movie=people relationships
  has_many :casts, 
           :include   => [ :person, :job ],
           :dependent => :destroy
  alias_method :episode_casts, :casts

  has_many :people,
           :through   => :casts
           
  has_many :characters,
           :finder_sql => 'select characters.* from characters
                             INNER JOIN casts ON characters.id = casts.character_id
                             WHERE casts.movie_id = #{self.id}'

  has_many :jobs,
           :through   => :casts
  
  has_many :actors, 
           :order     => :position, 
           :include   => :person,
           :dependent => :destroy

  # Production Companies
  has_many :production_companies,
           :order     => :position,
           :include   => :company,
           :dependent => :destroy

  has_many :companies,
           :through   => :production_companies,
           :order     => 'production_companies.position'

  has_many :votes,
           :dependent => :destroy
           
  has_many :trailers,
           :extend    => LocalFinder,
           :dependent => :destroy

  # Languages used in the Movie
  has_and_belongs_to_many :languages, 
                          :join_table => 'movie_languages',
                          :order   => 'movie_languages.position',
                          :after_add => Proc.new{ |m,l| m.add_to_changed_attributes( Language.to_s.underscore, nil, l.id ) },
                          :after_remove => Proc.new{ |m,l| m.add_to_changed_attributes( Language.to_s.underscore, l.id, nil ) }

  # Countries the Movie has been filmed in.
  has_and_belongs_to_many :countries,
                          :join_table => 'movie_countries',
                          :order   => 'movie_countries.position',
                          :after_add => Proc.new{ |m,c| m.add_to_changed_attributes( Country.to_s.underscore, nil, c.id ) },
                          :after_remove => Proc.new{ |m,c| m.add_to_changed_attributes( Country.to_s.underscore, c.id, nil ) }

  # References to other movies
  has_many                :references,
                          :finder_sql => 'SELECT * from movie_references where movie_id = #{self.id}'

  # reversing the :references relation
  has_many                :referencing_movies,
                          :class_name  => 'Reference',
                          :foreign_key => 'referenced_id'

  # the original cover of the movie
  has_one  :image,
           :as        => :related_object,
           :dependent => :destroy
  alias :cover :image

  # user votable movie-user categories like genres, plot keywords, etc.
  has_many :movie_user_categories,
           :dependent => :destroy

  # user written reviews
  has_many :reviews,
           :as => :related_object,
           :dependent => :destroy
           
  has_many  :popularity_histories,
            :as => :related_object
            
  has_many  :vote_histories,
            :as => :related_object

  acts_as_tree :order => "end, id"

  belongs_to :creator, :class_name => 'User', :foreign_key => :creator_id

  # Respect the Movie-Hierarchy
  validates_each :parent do |record, attr, value|
    record.errors.add "Don't set yourself as a parent" if !value.nil? and record.id == value.id
    record.errors.add "Don't set your parent to one of your children" if record.all_children_ids.include?( value.id ) unless value.nil?
    record.errors.add "Invalid Parent #{value.class}" unless record.class.valid_parents.include?( value.class ) or value.nil?
  end

  # Validation of certain attributes
  validates_length_of       :name,
                            :in => 1..100,
                            :too_short => "is too short. Please enter at least %d characters.",
                            :too_long => "is too long. Please enter up to %d characters."
                            
  validates_format_of       :end,
                            :with => /\d\d\d\d-\d\d?-\d\d?/,
                            :on => :update,
                            # do not trigger automatic end recalculation in
                            # this place, only validate a manually set end
                            # date here
                            :if => Proc.new{ |m| !m['end'].nil? and ![Series, MovieSeries].include?(m.class) }
                            #:if => Proc.new{ |m| !m.end.nil? }

  
  validates_numericality_of :runtime

  validates_numericality_of :budget

  validates_numericality_of :revenue

  validates_inclusion_of    :status, :in => VALID_STATUS_TYPES

  # Overwriting the LocalName#name method
  def name
    read_attribute(:name)
  end

  if not defined?(MOVIE_CONFIGURATION) 
    MOVIE_CONFIGURATION = { :languages            => true,
                            :countries            => true,
                            :production_companies => true,
                            :budget               => true,
			    :series_type          => false,
                            :runtime              => true,
                            :date                 => true,
                            :status               => true,
                            :cast                 => true,
                            :reviews              => true,
                            :references           => true,
                            :statistics           => false,
                            :votes                => true,
                            :trailers             => true,
                            :inheritable_cast     => false }
  end

  def self.configure( options = MOVIE_CONFIGURATION )
    options.each do |config_key, value|
      (class << self; self; end).class_eval do
        define_method( "has_#{config_key}?" ) do
          return value
        end
      end
    end
  end

  self.configure
  
  # Valid Child-Classes for a Movie.
  def self.valid_children
    []
  end

  # Valid Parent-Classes for a Movie.
  def self.valid_parents
    [ MovieSeries ]
  end

  # == Movie-Categories
  #
  # Fetch all assigned Categories for a movie. This method returns all categories, ordered by the number of votes.
  # The categories are not split into the separate Category-Types. You can fetch categories by type by using the
  # methods, named after each type of Category.
  # See Category for more infomation about the Category-Types and Category#categories_for_movie for the implementation
  # 
  # Use category_ids if you want to check, if a catgory is assigned to a movie.
  #
  # == Example
  #
  #  >> Movie.find(10).categories.size
  #  => 10
  #  >> Movie.find(10).genres.size
  #  => 2
  # 
  def categories
    Category.categories_for_movie self
  end
  
  # Fetch all Category-ids (Categories and Plot Keywords) via sql from the database. If you want to see, if a 
  # Category is already assigned to a movie, use @movie.category_ids.include?( @category.id ) which is much faster
  # then using @movie.category.include?( @category )
  def category_ids
    ActiveRecord::Base.connection.select_values( "SELECT DISTINCT c.id from categories as c, movie_user_categories as muc
                                                  where muc.category_id = c.id and muc.movie_id = #{self.id}" ).map(&:to_i)
  end

  # Define the Category-Type methods like like my_movie.genres or my_movie.terms
  Category::CATEGORY_TYPES.each { |category_type| 
    define_method category_type.underscore.pluralize do
      categories.delete_if { |c| c.root != Category.send(category_type.underscore) }
    end
  }
  
  # Fetch all assigned Plot Keywords of a movie. The Plot Keywords are ordered by number of votes.
  # see Category.keywords_for_movie
  def plot_keywords
    Category.keywords_for_movie self
  end
  alias_method :keywords, :plot_keywords


  # get the position of this part in a movie-series
  def part_position
    return self.parent.children.index(self) rescue nil
  end
  
  # get the number of this part in a movie-series,
  # like position, but +1
  def part_number
    # returns season number in tree (season 0 -> season 1)
    return self.part_position + 1 rescue nil
  end  
  
  def previous_part
    # return nil if there is no previous part
    self.part_position == 0 ? nil : self.parent.children.at(self.part_position-1) rescue nil
  end
  
  def next_part
    # return nil if its the last part
    self.part_position == self.parent.children.size ? nil : self.parent.children.at(self.part_position+1) rescue nil
  end

  # = Movie-Jobs
  # 
  # Fetch members of the production by their Job. The most important Jobs can be fetched by 
  # Methods accorting to their Job-Name.
  # These methods return Cast objects,
  # 
  # == Example
  # 
  #   >> Movie.find(11).people.size
  #   => 20
  #   >> Movie.find(11).authors.size
  #   => 2
  #   >> Movie.find(11).authors.first.person.name
  #   => "John Author"
  Job::IMPORTANT_JOBS.each { |name, id|
    define_method name.to_s.pluralize do
      Cast.employees( self, Job.send(name) )
    end
  }

  # Fetch members of the core crew of a movie. The jobs, that are part of the core crew
  # are defined in Job::CREW_MEMBERS.
  def crew
    Job::CREW_MEMBERS.collect { |member|      
      self.send( member.to_s.pluralize )
    }.flatten
  end

  def trailer( language = Locale.base_language )
    trailer = trailers.local( language )
    trailer.empty? ? Trailer.new : trailer.first
  end

  def has_trailer?( language = Locale.base_language )
    return false unless self.class.has_trailers?
    if not trailers.local( language ).empty?
      return true
    elsif (language != Locale.base_language) and not trailers.local( Locale.base_language ).empty?
      return true
    end
    return false
  end

  # Return the production year for the movie, if this is a movie-series, series
  # or a season, it will return a range, not a single year, if the series was
  # produced in more than one year.
  # @see MovieSeries#production_year for the implementation for series
  # @see MovieHelper#production for the usage in a view
  def production_year
    self.end.nil? ? nil : self.end.year
  end
  
  # Delete a specific category from a movie. This will delete all MovieUserCategory rows
  # in the database, therefore deleting all votes for that category.
  def delete_category( category )
    MovieUserCategory.destroy_all [ "movie_id = ? and category_id = ?", self.id, category.id ]
  end
  
  def similar_movies
    Searcher.find_similar_movies( self )
  end

  def to_search_result_xml( xml, language = Locale.base_language )
    xml.movie do
      xml.id self.id
      xml.name self.local_name( language )
      xml.abstract self.abstracts.local(language).first.nil? ? "" : self.abstracts.local( language ).first.data
      xml.releaseDate self.end, :type => :date
      xml.image self.image.nil? ? nil : self.image.filename
    end
  end


  # Update the vote-cache for a movie. As soon as a user enteres a vote for a movie, the
  # vote_cache will be updated using this method.
  # def update_vote
  #   total = 0.0
  #   self.votes.each { |v|
  #     total = total + v.vote
  #   }
  #   self.update_attribute(:vote, total / votes.length) unless votes.empty?
  # end

  def Movie.valid_types
    [ MovieSeries, Movie, Series, Season, Episode ]
  end

  def Movie.valid_status_types
    VALID_STATUS_TYPES
  end

  def Movie.search_localized( query, lang )
    Searcher.search_movies( query, lang.code )
  end

  def Movie.search_localized_by_prefix( query, lang )
    Searcher.search_movies_by_prefix( query, lang.code )
  end

  def Movie.search_by_year( year, page = 1 )
    start_date = Date.new(year.to_i, 1, 1)
    end_date   = Date.new(year.to_i, 12, 31)
    Movie.find :all, :page => { :current => page, :size => 24 }, 
               :conditions => "end >= '#{start_date.to_s}' and end <= '#{end_date.to_s}' and type in ('Movie', NULL)",
               :order => 'end'
  end

  def Movie.popular
    Movie.find(:all, 
               :limit => 10,
               :conditions => [ 'type in (?)', ['Movie', 'Episode', nil] ],
               :order => "popularity DESC")
  end

  def Movie.highest_rated
    Movie.find(:all, 
               :limit => 10,
               :conditions => [ 'type in (?)', ['Movie', 'Episode', nil] ],
               :order => "vote DESC")
  end
  
  def Movie.top_100_movies
    Movie.find(:all, 
               :limit => 100,
               :conditions => [ 'votes_count > 5 and type in (?)', ['Movie', nil] ],
               :order => "vote DESC")
  end
  
  def Movie.bottom_100_movies
    Movie.find(:all,
               :limit => 100,
               :conditions => [ 'votes_count > 5 and type in (?)', ['Movie', nil] ],
               :order => "vote ASC")
  end

  def Movie.recently_added(options = {})
    options.reverse_merge! :limit      => 10,
                           :conditions => [ 'movies.type in (?)', ['Movie', 'Episode', nil] ], 
                           :order      => "movies.created_at DESC"
    Movie.find :all, options
  end
  
  def Movie.of_the_day
    Movie.find(:first,
               :limit => 1,
               :conditions => [ 'movie_of_the_day = ?', Date.jd(DateTime.now.jd).to_s ])
  end
  
  def Movie.anniversary
    [ 100, 75, 50, 40, 30, 25, 20, 10, 5 ].each do |years_ago|
      movie = Movie.find(:first,
                 :limit => 1,
                 :conditions => [ 'end = ? and type in (\'Movie\', \'Episode\')', years_ago.years.ago.to_date.to_s ],
                 :order => :popularity)
      return { years_ago => movie } unless movie.nil?
    end
    return nil
  end
  
  def Movie.must_see_today
    Movie.find(:first,
               :limit => 1,
               :order => "popularity desc",
               :conditions => [ 'end < ? and end > ? and type in (\'Movie\', \'Episode\')', 7.day.from_now.to_date.to_s, 60.days.ago.to_date.to_s ] )
  end

  def Movie.random_movie
    m = Movie.find_by_sql("select * from movies where vote > 6.0 order by rand() limit 1")
    m.first
  end
  
  def median_rating
    rating_cumulated = 0
    i = 0.0
    self.votes.each do |r|
      rating_cumulated += r.vote
      i += 1
    end
    if i == 0
      return 0
    else
      return (rating_cumulated/i)
    end
  end
  
  def ratings_by_rating
    
  end
  
  
  def update_children
    # remove children
    @movie.children.each { |m|
      if not m.attribute_frozen?( :parent )
        if not params[:movies].include?( m.id.to_s )
          m.parent = nil
          m.save
        end
      end
      movies.delete( m.id.to_s )
    }
    # add children
    movies.each { |m|
      movie = Movie.find(m)
      if not movie.attribute_frozen?( :parent )
        movie.parent = @movie
        movie.save
      end
    }
  end

end
