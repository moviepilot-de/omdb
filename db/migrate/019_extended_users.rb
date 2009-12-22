class ExtendedUsers < ActiveRecord::Migration

  def self.up
    add_column :principals, :date_of_birth, :date, :null => true
    add_column :principals, :country_id, :integer, :null => true
    add_index "principals", "country_id"
    add_index "groups_users", ["user_id", "group_id"], :unique => true
  end
    
  def self.down
    remove_index "principals", "country_id"
    remove_column :principals, :country_id
    remove_column :principals, :date_of_birth
  end
  
end