class Person < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include Statistics
  include MovieListings
  include Logging

  class_inheritable_accessor :stub_fields

  freezable_attribute :name
  freezable_attribute :birthday
  freezable_attribute :birthplace
  freezable_attribute :deathday
  freezable_attribute :homepage

  db_depending_objects
  #depending_objects [ :self, :movies, :jobs ]

  stub [ :birthday ], :if => Proc.new { |value| value == "n/a" }
  stub [ :birthplace ], :if => :empty?

  has_many :casts, 
           :order     => 'casts.type, movies.end DESC',
           :include   => :movie,
           :dependent => :destroy

  has_many :name_aliases, :as => :related_object

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

  has_many :movies, 
           :through => :casts,
           :select  => 'DISTINCT movies.*',
           :order   => 'end'

  has_many :chronological_movies, 
           :class_name => "Movie",
           :through    => :casts,
           :source     => :movie,
           :select     => 'DISTINCT movies.*',
           :conditions => "movies.end IS NOT NULL AND movies.end <= '#{Date.today.to_s}'",
           :order      => "movies.end ASC"

  has_many :jobs,
           :select     => 'DISTINCT jobs.*',
           :through    => :casts

  has_many :highest_rated_movies,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies 
                             INNER JOIN casts ON movies.id = casts.movie_id 
                           WHERE 
                             (casts.person_id = #{id}) ORDER BY movies.vote DESC 
                           LIMIT 25'

  has_many :upcoming_movies,
           :through    => :casts,
           :source     => :movie,
           :limit      => 3,
           :select     => 'DISTINCT movies.*',
           :order      => "movies.end",
           :conditions => "movies.end > '#{Date.today.to_s}'",
           :class_name => "Movie"
           
  has_many :popular_movies,
           :through    => :casts,
           :source     => :movie,
           :select     => 'DISTINCT movies.*',
           :limit      => 10,
           :conditions => "movies.end < '#{Date.today.to_s}'",           
           :order      => "movies.popularity",
           :class_name => "Movie"

  has_one  :image,
           :as        => :related_object,
           :dependent => :destroy
  alias :portrait :image

  validates_presence_of :name

  def all_movies( limit, offset )
    movies.slice( offset, limit )
  end

  def aliases
    name_aliases
  end
  
  def birthday
    orig_bday = read_attribute(:birthday)
    ( orig_bday.nil? or orig_bday.to_s == '1900-01-01' ) ? 'n/a' : orig_bday
  end
  
  def birth_year
    orig_bday = read_attribute(:birthday)
    ( orig_bday.nil? or orig_bday.to_s == '1900-01-01' ) ? 'n/a' : orig_bday.year
  end
  
  def merge( people )
    people.delete_if { |p| p.id == self.id }
    people.each do |p|
      p.casts.each do |cast|
        cast.person = self
        cast.save!
      end
      self.name_aliases << NameAlias.new( :name => p.name, :language => Language.independent_language ) unless p.name == self.name
      # we need to reload the person, otherwise all casts would
      # be gone, as AR is to stupid to see that i just removed
      # the casts from that person, and will use his cached records for casts.
      p.reload.destroy
    end
    self.save
  end
  
  def assoc_column_name
    Inflector.singularize(self.class.table_name) + "_id"
  end
  
  def to_search_result_xml( xml, language = Locale.base_language )
    xml.person do
      xml.id self.id
      xml.name self.name
      xml.abstract self.abstracts.local(language).first.nil? ? "" : self.abstracts.local( language ).first.data
      xml.birthDay self.birthday, :type => :date
    end
  end
  

  def self.search( query, lang )
    Searcher.search_people( query, lang.code )
  end

  def self.search_by_prefix( query, lang, offset = 0, limit = 100 )
    Searcher.search_people_by_prefix( query, lang.code, offset, limit )
  end

  def self.find_orphans
    Person.find_by_sql( "SELECT people.*, casts.id as cast_id FROM people LEFT JOIN 
         casts ON people.id = casts.person_id WHERE ISNULL(casts.id)" )
  end
  
  def self.popular
    Person.find(:all,
                :limit => 10,
                :order => 'popularity DESC')
  end
  
  def self.of_the_day
    Person.find(:first,
                :limit => 1,
                :conditions => [ 'person_of_the_day = ?', Date.jd(DateTime.now.jd).to_s ])
  end

  def self.born_today
    [ 150, 125, 100, 75, 60, 50, 40, 30, 25, 20, 18 ].each do |years_ago|
      person = Person.find(:first,
                           :limit => 1,
                           :conditions => [ 'birthday = ?', (Time.now.year - years_ago).to_s + "-" + Time.now.to_date.strftime('%m') + "-" + Time.now.to_date.strftime('%d') ],
                           :order => :popularity)
      return { years_ago => person } unless person.nil?
    end
    return nil
  end
  
  def self.popular_actors
    Person.find( :all,
                 :limit      => 10,
                 :include    => :casts,
                 :order      => 'people.popularity DESC',
                 :conditions => [ 'casts.job_id = ?', Job.actor.id ] )
  end
  
  def self.person_of_the_day_candidate
    Person.find_by_sql( 'select * from people where (select count(*) from casts where casts.person_id = people.id) > 9 order by rand() limit 1;' ).first
  end

end
