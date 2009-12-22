class Category < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include Statistics
  include LocalName
  include MovieListings
  include TreeStructure
  include Logging

  class_inheritable_accessor :stub_fields

  acts_as_tree
  alias original_root root
  
  # caching des category root - das spart 'nen Haufen SQL-Queries ein, und das
  # root einer category duerfte ja auch ziemlich statisch sein...
  # TODO expire when category hierarchy changes
  def root
    cache_key = "#{RAILS_ENV}_Category_#{id}_root"
    root = Cache.get(cache_key)
    unless Category === root
      root = original_root
      Cache.put cache_key, root, 86400
    end
    root
  end

  freezable_attribute :self
  freezable_attribute :parent

  db_depending_objects

  stub [ :parent ], :if => Proc.new { |p| p.id == Category.default_keyword_parent.id }

  has_many :name_aliases,
           :as        => :related_object,
           :order     => :position,
           :extend    => LocalFinder, 
           :dependent => true

  has_many :movie_user_categories, 
           :dependent => true

  has_many :abstracts, 
           :as        => :related_object,
           :extend    => LocalFinder, 
           :dependent => true

  has_many :pages, 
           :as        => :related_object,
           :extend    => LocalFinder, 
           :dependent => true

  has_many :movies,
           :through => :movie_user_categories
           
  has_many :popular_movies,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies 
                             INNER JOIN movie_user_categories ON movies.id = movie_user_categories.movie_id 
                           WHERE 
                             (movie_user_categories.category_id = #{id}) ORDER BY movies.popularity DESC
                           LIMIT 10'

  has_many :highest_rated_movies,
           :class_name => "Movie",
           :finder_sql => 'SELECT DISTINCT movies.* FROM movies 
                             INNER JOIN movie_user_categories ON movies.id = movie_user_categories.movie_id 
                           WHERE 
                             (movie_user_categories.category_id = #{id}) ORDER BY movies.vote DESC
                           LIMIT 25'

  has_many :chronological_movies, 
           :class_name => "Movie",
           :through    => :movie_user_categories,
           :source     => :movie,
           :select     => 'DISTINCT movies.*',
           :conditions => "movies.end IS NOT NULL",
           :order      => "movies.end ASC"

  has_many :upcoming_movies,
           :through    => :movie_user_categories,
           :source     => :movie,
           :select     => 'DISTINCT movies.*',
           :limit      => 3,
           :order      => "movies.end",
           :conditions => "movies.end > '#{Date.today.to_s}'",
           :class_name => "Movie"

  has_one  :image,
           :as        => :related_object,
           :dependent => :destroy  

  CATEGORY_TYPES = [ "Genre", "Source", "Type", "Standing", "Audience", "Epoch",
                      "Production", "PlotKeyword", "Term" ] unless defined? CATEGORY_TYPES
  
  def merge( categories )
    parent_ids = self.objects_to_root.collect {|c| c.id }
    categories.delete_if{ |c| self.id == c.id or parent_ids.include?(c.id) }
    self.grab_children( categories )
    self.grab_votes( categories )
    self.grab_aliases( categories )
    self.save
    categories.each do |c|
      # We need to reload to make sure AR does not use its
      # cached hierarchy data. This would destroy more than
      # we want to.
      c.reload.destroy
    end
  end
  

  def full_flattened_name(language)
    elements = ancestors.reverse
    elements.map {|cat| cat.local_name(language)}.<<(local_name(language)).join(" > ")
  end

  # Like full_flattened_name, but excluding the root element
  def flattened_name(language)
    elements = ancestors.reverse
    elements.delete_at(0)
    elements.map {|cat| cat.local_name(language)}.<<(local_name(language)).join(" > ")
  end

  def categories_to_root
    ancestors.reverse << self
  end
  alias_method :objects_to_root, :categories_to_root

  def categories_from_root
    cats = ancestors.reverse.push(self)
    cats.delete_at(0)
    cats
  end

  def ordered_children( language = Locale.base_language )
    children.slice(0, 100).sort { |a,b|
      a.local_name( language ) <=> b.local_name( language )
    }
  end
  
  def destroy_all_votes_for_movie( movie )
    MovieUserCategory.destroy_all "movie_id = #{movie.id} and category_id = #{self.id}"
  end
  
  # gives back the vote count on an category, counts all positive votes and substracts the negative ones
  def count_for_movie(movie)
    result = connection.execute(
              ActiveRecord::Base.send( :sanitize_sql,
                [ "SELECT sum(value) as sum from movie_user_categories WHERE movie_id = ? AND 
                  category_id = ?", movie.id, self.id ] ) ).fetch_row.first
      
    result.nil? ? 0 : result.to_i
  end

  def all_movies( limit, offset )
    Movie.find_by_sql [ "select distinct m.* from movies m inner join movie_user_categories as muc on m.id = muc.movie_id where muc.category_id in (?) and m.end is not null order by m.end limit ? offset ?", all_children.push(self).collect {|c| c.id }, limit, offset ]
  end
  
  def all_movies_paged( page = 1 )
    Movie.find(:all, :page => { :size => 24, :current => page, :count => all_movie_count },
       :select     => "DISTINCT movies.*",
       :joins      => "INNER JOIN movie_user_categories as muc on movies.id = muc.movie_id",
       :conditions => "muc.category_id in (#{all_children.push(self).collect{|c| c.id }.join(",")}) and movies.end is not null",
       :order      => "movies.end")
  end
  
  def all_movie_count
    result = connection.select_one("select (select count(distinct movies.id) from movies inner join movie_user_categories as muc on movies.id = muc.movie_id and muc.category_id in (#{all_children.push(self).collect{|c| c.id }.join(",")}) and movies.end is not null) as movie_count")
    result["movie_count"].to_i
  end

  def all_movies_by_rating
    Movie.find_by_sql [ "select distinct m.* from movies m inner join movie_user_categories as muc on m.id = muc.movie_id where muc.category_id in (?) order by m.vote DESC limit 25;", all_children.push(self).collect {|c| c.id } ]
  end

  def all_movies_by_revenue
    Movie.find_by_sql [ "select distinct m.* from movies m inner join movie_user_categories as muc on m.id = muc.movie_id where muc.category_id in (?) and m.revenue > 1 order by m.revenue DESC limit 25;", all_children.push(self).collect {|c| c.id } ]
  end
  
  def self.all_categories(movie)
    find_by_sql [ "select c.id, c.parent_id, count(c.id) as votes from categories c, movie_user_categories muc where muc.category_id = c.id and muc.movie_id = ? group by c.id order by votes desc", movie.id ]
  end
  
  def self.categories_for_movie(movie)
    keyword = self.plot_keyword
    self.all_categories( movie ).delete_if { |c|
      c.root.id == keyword.id
    }
  end

  def self.keywords_for_movie(movie)
    keyword = self.plot_keyword
    self.all_categories( movie ).delete_if { |c|
      c.root.id != keyword.id
    }
  end

  def self.categories
    find(:all)
  end
  
  def self.search_localized( query, language )
    Searcher.search_categories( query, language.code )
  end

  def self.search_localized_by_type( type, query, language )
    Searcher.search_categories_by_type( type, query, language.code )
  end

  def self.search_by_prefix( q, lang, offset = 0, limit = 100 )
    Searcher.search_categories_by_prefix( q, lang.code, offset, limit )
  end

  def self.search_keywords_by_prefix( q, lang, offset = 0, limit = 100 )
    Searcher.search_keywords_by_prefix( q, lang.code, offset, limit )
  end

  class <<self
    CATEGORY_TYPES.each_with_index do |type, idx|
      name = type.underscore
      class_eval <<-END
        def #{name}
          @@#{name} ||= Category.find(#{idx+1})
        end
        
        def popular_#{name.pluralize}
          Searcher.popular_categories_by_type(self.send("#{name}").id).collect { |l| l.to_o }
        end
      END
    end
  end

  def self.default_keyword_parent
    @@default_keyword_parent ||= Category.find( 1000 )
  end
  
  def base_name
    root = self.root
    returning basename = CATEGORY_TYPES.map(&:underscore).find { |type| root == self.class.send(type) } do
      raise "Unknown base_name for category #{self.id}" unless basename
    end
  end

  def self.initialize
    Category.destroy_all
    # This is neccessary to reset the auto_increment counter.. just dropping
    # all records won't help. This is MySQL specific.
    self.reset_auto_increment
    CATEGORY_TYPES.each { |c|
      cat = Category.create()
      cat.aliases.create(:name => c.humanize, :language => Locale.base_language)
    }
  end
  
  def grab_children( categories )
    categories.each do |category|
      category.children.each do |child|
        child.parent = self
        child.save!
      end
    end
  end
  
  def grab_votes( categories )
    categories.each do |category|
      category.movie_user_categories.each do |muc|
        new_muc = MovieUserCategory.new( :user => muc.user, :movie => muc.movie, :category => self )
        new_muc.save
        muc.destroy
      end
    end
  end
  
  def grab_aliases( categories )
    categories.each do |category|
      category.name_aliases.each do |a|
        new_alias = NameAlias.new( :name => a.name, :language => a.language, :related_object => self )
        new_alias.save
        a.destroy
      end
    end
  end
  
  def to_search_result_xml( xml, language = Locale.base_language )
    xml.movie do
      xml.id self.id
      xml.name self.local_name( language )
      xml.abstract self.abstracts.local(language).first.nil? ? "" : self.abstracts.local( language ).first.data
    end
  end
  
end
