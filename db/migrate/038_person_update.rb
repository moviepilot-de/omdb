class PersonUpdate < ActiveRecord::Migration
  def self.up
    add_column :people, :homepage, :string, :default => '', :null => false
    add_column :people, :birthplace, :string, :default => '', :null => false
  end

  def self.down
    remove_column :people, :homepage
    remove_column :people, :birthplace
  end
end
