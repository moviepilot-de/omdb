class Popularity < ActiveRecord::Base
  belongs_to :language

  def self.last_popularities
    yesterday = (DateTime.now - 2).strftime('%Y-%m-%d')
    find(:all,
         :conditions => "created_at > '#{yesterday}\'")
  end

  # def self.

end
