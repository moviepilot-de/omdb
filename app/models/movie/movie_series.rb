class MovieSeries < Movie
  include TreeStructure
  include Statistics
  
  depending_objects [ :self, :children, :siblings, :people, :categories, :plot_keywords, :characters, :pages, :countries, :characters ]

  disable_logging_of [ :vote, :votes_count, :end ]

  stub [ :children ], :if => :empty?, :clear => true
  
  # Set configuration options for this class.
  MOVIE_CONFIGURATION = self.superclass::MOVIE_CONFIGURATION.merge(
    { :languages            => false,
      :countries            => false,
      :production_companies => false,
      :budget               => false,
      :runtime              => false,
      :date                 => false,
      :status               => false,
      :statistics           => true,
      :reviews              => false,
      :references           => false,
      :cast                 => false,
      :votes                => false,
      :trailers             => false,
      :inheritable_cast     => false }
  )
  
  self.configure MOVIE_CONFIGURATION
  
  def self.valid_children
    [ Movie, Series ]
  end
  
  def self.valid_parents
    []
  end

  def self.popular
    MovieSeries.find(:all, 
                     :limit => 10,
                     :order => "popularity DESC")
  end

  def all_movies( limit, offset )
    all_children.delete_if { |child| ![ Movie, Episode ].include?(child.class) }
  end
  
  # Overwrite default Movie#directors method
  def directors
    directors = []
    self.children.each { |m|
      m.directors.slice(0,1).each { |d| directors.push(d) }
    }
    directors.uniq
  end

  # Fetch the first production date of all children
  def start
    start = []
    self.children.each { |c| 
      start.push(c.start) unless c.start.nil?
      start.push(c.end) unless c.end.nil?
    }
    start.sort.first
  end

  # Fetch the last production date of all children
  def end
    dates = self.children.map(&:end).compact
    #self.children.each { |c| 
    #  dates.push(c.end) unless c.end.nil?
    #}
    # set the end-date for this movie series if it has been changed
    # (like a child has been added or an existing has been removed)
    # Changing the :end attribute does not fire a logging, as :end
    # is set to be unloggable for series.
    last = dates.sort.last
    update_attribute_with_validation_skipping( :end, last ) unless self.attributes["end"] == last or self.class == Season
    last
  end
  
  def production_year
    if self.children.empty?
      nil
    else
      if not self.end.nil? and not self.start.nil?
        if self.start.year == self.end.year
          self.start.year
        else
          Range.new( self.start.year, self.end.year )
        end
      else
        self.start.nil? ? ( self.end.nil? ? nil : self.end.year ) : self.start.year
      end
    end
  end
  
  def start_year
    return self.start.year unless self.start.nil?
  end
  
  def end_year
    return self.end.year unless self.end.nil?
  end

  # Calculate the avarage vote of all children
  def vote
    vote = 0
    self.children.each { |c|
      vote = vote + c.vote
    }
    if self.children.size > 0
      (vote / self.children.size)
    else
      vote
    end
  end


end
