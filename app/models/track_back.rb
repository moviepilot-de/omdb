class TrackBack < ActiveRecord::Base
  belongs_to :language
  validates_presence_of :url
  validates_presence_of :title
end
