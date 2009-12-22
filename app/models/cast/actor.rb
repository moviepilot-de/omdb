class Actor < Cast
  acts_as_list :scope => :movie

  belongs_to :character

  has_many :name_aliases,
           :as        => :related_object,
           :extend    => LocalFinder,
           :dependent => true

  def aliases
    name_aliases
  end
  
  def self.default_job
    Job.actor
  end
  
end
