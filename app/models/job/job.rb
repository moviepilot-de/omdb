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


# A Job is basically just a description on who does what on a movie. The
# most obvious jobs in a Movie is the director, the actors or authors. 
# But as a comprehensive encyclopedia, we try to catch up with all possible
# jobs that one can have during the production of a movie.

class Job < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include LocalName
  include TreeStructure
  include Logging

  freezable_attribute :self
  freezable_attribute :parent

  depending_objects [ :self, :movies, :pages ]

  validates_presence_of :parent, :if => Proc.new { |job| job.class == Job }
  validates_associated :name_aliases

  acts_as_tree

  has_many :casts,
           :dependent => :destroy

  has_many :name_aliases,
           :as        => :related_object,
           :order     => :position,
           :extend    => LocalFinder,
           :dependent => :destroy

  has_many :abstracts,
           :as        => :related_object,
           :extend    => LocalFinder,
           :dependent => :destroy

  has_many :pages,
           :as        => :related_object,
           :extend    => LocalFinder,
           :dependent => :destroy

  has_many :people,
           :through => :casts
           
  has_many :popular_people,
           :class_name => "Person",
           :finder_sql => 'SELECT DISTINCT people.* FROM people 
                             INNER JOIN casts ON people.id = casts.person_id 
                           WHERE 
                             (casts.job_id = #{id}) ORDER BY people.popularity DESC
                           LIMIT 24'

  has_many :prominent_people,
           :through => :casts,
           :class_name => "Person",
           :order => "people.popularity"

  has_many :movies,
           :through => :casts

  has_one  :image,
           :as        => :related_object,
           :dependent => :destroy

  def ordered_children( lang = Locale.base_language )
    children.sort { |a,b|
      a.local_name( lang ) <=> b.local_name( lang )
    }
  end


  # Fetch the Department of the Job. The Department is always the Root of the Job
  def department
    self.root
  end

  def flattened_name( lang = Locale.base_language )
    elements = ancestors.reverse
    elements.map { |job|
       job.local_name( lang )
    }.<<(local_name( lang )).join(" > ")
  end

  if not defined?(IMPORTANT_JOBS)
    IMPORTANT_JOBS = { :director => 21, :producer => 16, 
                       :director_of_photography => 23,
                       :editor   => 33, :author  => [ 13, 100, 104 ], 
                       :actor    => 15, :composer => 27 }
  end
  
  if not defined?(CREW_MEMBERS)
    CREW_MEMBERS = [ :director, :author, :producer, :director_of_photography, :editor, :composer ]
  end
  
  IMPORTANT_JOBS.each { |name, id|
    (class << Job; self; end).class_eval {
      body = lambda {
        class_variables.include?("@@#{name}") ? 
            class_variable_get("@@#{name}") : 
            class_variable_set("@@#{name}", Job.find( id ))
      }
      define_method( "#{name}", body )
     }
  }

  def self.default_job
    @@default_job ||= Job.find( 681 )
  end
  
  def self.popular
    Job.find(:all,
             :limit => 30,
             :order => 'popularity DESC')
  end
  
  def self.merge_jobs(surviving_job, jobs_to_be_nuked)
    #error handling:
    #return if cats.empty? or cats.first
    #make the first name_alias really the first one
    parent_job.name_aliases.each_with_index do |na,i| 
      na.position = i + 1
      na.save
    end
    #take the cats to be merged and loop thru them
    jobs.each do |j|
      #if there is one take the first level child of j 
      j.children.each do |child|
        #and make them children of the the new parent cat
        #the deeper level children should then be automatically children
        #of the parent_cat
        child.parent = parent_job 
        child.save
      end      
      #after having done that I'll make the to be merged cat an name_alias of the parent_cat
      #and make all its name_aliases name_aliases to the parent
      #same goes for mvc s and pages, abstracts and index pages are omitted
      j.casts.each { |c| parent_job.casts << c } 
      #special treatment for the name_aliases
      offset = parent_job.name_aliases.size + 1
      j.name_aliases.each_with_index do |na, i|
        na.position = offset + i
        na.save
        parent_job.name_aliases << na
      end
      #j.abstracts.each { |abs| parent_job.abstracts << abs } 
      j.pages.each { |p| ( parent_job.pages << p ) unless p.page_name = 'index' }
      #that should have moved all the associated objects to the new category
      #and it should not have any children anymore
      #test name_aliases
      return if not parent_job.save
      Job.find(j.id)
      #very important reload (a find is not enough), since otherwise rails
      #would start deleting dependent stuff based on the session information
      j.reload
      #now the job can be deleted, its dependent stuff will be too (abstracts, wiki index, images)
      j.destroy
    end
  end
  

  # == Ferret Methods
  
  def self.search( q, lang = Locale.base_language )
    Searcher.search_job( q, lang.code )
  end
  
  def self.search_by_prefix( q, lang, limit = 0, offset = 100 )
    Searcher.search_job_by_prefix( q, lang.code, limit, offset )
  end
  
end
