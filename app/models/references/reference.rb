class Reference < ActiveRecord::Base
  include Freezable

  depending_objects [ :movie, :referenced_movie ]

  belongs_to :movie

  belongs_to :referenced_movie,
             :foreign_key => 'referenced_id',
             :class_name => 'Movie'

  set_table_name 'movie_references'

  acts_as_list

  def superclass
    self.class.base_class
  end

  def Reference.valid_types
    [ Influence, Reference, Remake, SpinOff, Homage, Parody ]
  end

  def self.random
    m = Reference.find_by_sql("select * from movie_references order by rand() limit 1")
    m.first
  end

end
