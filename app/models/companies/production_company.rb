class ProductionCompany < ActiveRecord::Base
  include Freezable

  belongs_to :movie
  belongs_to :company

  validates_presence_of :movie, :company

  depending_objects [ :movie, :company ]

  def init(company, movie)
    self.company = company
    self.movie   = movie
  end
end
