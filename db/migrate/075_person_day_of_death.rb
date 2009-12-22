class PersonDayOfDeath < ActiveRecord::Migration
  def self.up
    add_column :people, :deathday, :date, :null => true
    add_column :person_versions, :deathday, :date, :null => true
    remove_column :people, :is_actor
    remove_column :people, :is_director
    remove_column :people, :is_author
    remove_column :person_versions, :is_actor
    remove_column :person_versions, :is_director
    remove_column :person_versions, :is_author
  end

  def self.down
    remove_column :people, :deathday
    remove_column :person_versions, :deathday
    add_column :people, :is_actor, :boolean, :default => false, :null => false
    add_column :people, :is_director, :boolean, :default => false, :null => false
    add_column :people, :is_author, :boolean, :default => false, :null => false
    add_column :person_versions, :is_actor, :boolean, :default => false, :null => false
    add_column :person_versions, :is_director, :boolean, :default => false, :null => false
    add_column :person_versions, :is_author, :boolean, :default => false, :null => false
  end
end
