class ColumnsForPortalViews < ActiveRecord::Migration
  def self.up
    add_column :people, :person_of_the_day, :date
    add_index :people, :person_of_the_day, :name => 'person_of_the_day_index'
  
    add_column :jobs, :popularity, :integer, :default => 0
    add_index :jobs, :popularity, :name => "job_popularity"
  end

  def self.down
    remove_column :people, :person_of_the_day
    remove_column :jobs, :popularity
  end
end
