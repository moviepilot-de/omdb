# Copyright (c) 2006 Benjamin Krause
#
# This is a person-movie relationship. Everyone working on a movie (like the
# director, actors, writers, etc.) are mapped by this 3-table relation object.
#
# Each Cast needs to have a movie, a person and a job. 
#
class Cast < ActiveRecord::Base
  include Freezable

  belongs_to :movie
  belongs_to :person
  belongs_to :job

  freezable_attribute :self

  depending_objects [ :movie, :person, :job ]

  # deprecated old field, will be removed in future versions
  attr_reader :new_comment

  # A Cast is only valid if consiting of a Person, a Movie and a Job
  validates_presence_of :movie, :person, :job

  def init(person, movie, job)
    self.person = person
    self.movie  = movie
    self.job    = job
    self
  end

  def self.employees( movies, jobs, recursive = false )
    Cast.find(:all, :conditions => [ "movie_id in (?) and job_id in (?)", 
                                      fetch_movie_ids( movies ), 
                                      fetch_job_ids( jobs, recursive ) ], 
                    :order => :position, :include => [ :person, :job ] )
  end

  private

  def self.fetch_movie_ids( movies )
    movies = movies.kind_of?(Array) ? movies : [ movies ]
    movies.collect { |m|
      if m.class == Episode and m.parent and m.parent.inherit_cast
        [ m.id, m.parent.id ]
      else
        m.id
      end
    }.flatten
  end

  def self.fetch_job_ids( jobs, recursive )
    jobs = jobs.kind_of?(Array) ? jobs : [ jobs ]
    jobs.collect {|j|
      if j.class == Department or recursive
        j.all_children_ids
      else
        [ j.id ]
      end
    }.flatten
  end

end
