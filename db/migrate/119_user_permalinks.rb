class UserPermalinks < ActiveRecord::Migration
  def self.up
    User.find( :all ).each do |u|
      u.save
    end
  end

  def self.down
  end
end
