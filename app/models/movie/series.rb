class Series < MovieSeries

  MOVIE_CONFIGURATION = self.superclass::MOVIE_CONFIGURATION.merge(
    { :series_type          => true }
  )

  self.configure MOVIE_CONFIGURATION

  # Valid Child-Classes for a Serie
  def self.valid_children
    [ Season, Episode ]
  end
  
  def self.valid_parents
    [ MovieSeries ]
  end

  def seasons
    self.children.find( :all, :conditions => "type = 'Season'" )
  end

  def episodes
    self.children.find( :all, :conditions => "type = 'Episode'" )
  end
  
  # Overwriting MovieSeries.directors
  def directors
    []
  end

  def Series.popular
    Series.find(:all, 
                :limit => 10,
                :order => "popularity DESC")
  end

  def self.valid_series_types
    [ :season_based, :mini_series, :soap ]
  end

end
