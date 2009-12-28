class Season < Series

  VALID_SEASON_TYPES = [ :regular, :specials ]

  depending_objects [ :self, :parent, :children, :siblings, :people, :categories, :plot_keywords, :characters, :pages, :countries, :characters ]

  stub [ :children ], :if => :empty?, :clear => true
  stub [ :parent ]

  # Set configuration options for this class.
  MOVIE_CONFIGURATION = self.superclass::MOVIE_CONFIGURATION.merge(
    { :budget               => true,
      :cast                 => true,
      :status               => true,
      :date                 => true,
      :series_type          => false,
      :season_type          => true,
      :season_number        => true,
      :production_companies => true,
      :inheritable_cast     => true }
  )

  self.configure MOVIE_CONFIGURATION

  alias :season_pos :part_position
  alias :season_number :part_number
  alias :previous_season :previous_part
  alias :next_season :next_part


  def self.valid_children
    [ Episode ]
  end

  def self.valid_parents
    [ Series ]
  end

  def episode_for_previous_season(movie)
    #show the previous ep if available, else got to the season site
    pos = ( self.previous_season.children.at(movie.episode_pos) ? movie.episode_pos : 0 )
    ( self.previous_season.children.empty? ? self.previous_season : self.previous_season.children.at(pos) ) rescue nil
  end
  
  def episode_for_next_season(movie)
    #show the previous ep if available, else got to the season site
    pos = ( self.next_season.children.at(movie.episode_pos) ? movie.episode_pos : 0 )
    ( self.next_season.children.empty? ? self.next_season : self.next_season.children.at(pos) ) rescue nil
  end
  
  def self.valid_series_types
    VALID_SEASON_TYPES
  end
end
