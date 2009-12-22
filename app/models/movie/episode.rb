class Episode < Movie
  class_inheritable_accessor :stub_fields
  
  depending_objects [ :self, :parent, :siblings, :people, :categories, :plot_keywords, :characters, :pages, :countries, :characters ]

  stub [ :end, :parent ], :clear => true
  stub [ :casts, :crew, :genres, :plot_keywords, :languages ], :if => :empty?
  stub [ :runtime ], :if => Proc.new { |value| value == 0 }
  
  # :TODO: This is slow.. include is nor used, we need to speed this up
  has_many :episode_and_season_casts, 
           :include    => [ :person, :job ],
           :class_name => "Cast",
           :finder_sql => 'SELECT * from casts where movie_id in (#{self.id}, #{self.parent.id})'
           
  has_many :episode_and_season_actors,
           :include    => [ :person, :job ],
           :class_name => "Actor",
           :order      => :position,
           :finder_sql => 'SELECT * from casts where movie_id in (#{self.id}, #{self.parent.id}) and type = \'Actor\''

  def self.valid_parents
    [ Season ]
  end

  # Set configuration options for this class.
  MOVIE_CONFIGURATION = self.superclass::MOVIE_CONFIGURATION.merge(
    { :production_companies => false,
      :trailers             => false,
      :budget               => false }
  )
  
  self.configure MOVIE_CONFIGURATION
  
  def Episode.popular
    Episode.find(:all, 
                 :limit => 10,
                 :order => "popularity DESC")
  end
  
  def episode_pos
    return self.parent.children.index(self)
  end
  
  def episode_number
    # returns episode number in tree + 1 (ep 0 -> ep 1)
    return episode_pos + 1
  end
  
  def previous_episode
    # return nil if there is no previous episode
    self.episode_pos == 0 ? nil : self.parent.children.at(self.episode_pos-1)    
  end
  
  def next_episode
    # return nil if its the last episode
    self.episode_pos == self.parent.children.size ? nil : self.parent.children.at(self.episode_pos+1)    
  end

  def casts
    if not self.parent.nil? and self.parent.inherit_cast
      episode_and_season_casts
    else
      episode_casts
    end
  end
  
  def actors
    if not self.parent.nil? and self.parent.inherit_cast
      episode_and_season_actors    
    else
      super
    end
  end

  private

  def cast_source
    if not self.parent.nil? and self.parent.inherit_cast
     [ self, parent ]
    else
      self
    end
  end

end
