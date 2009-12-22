class Popularity < ActiveRecord::Migration
  def self.up
    add_column :movies, :popularity, :integer, :default => 0, :null => false
    add_column :people, :popularity, :integer, :default => 0, :null => false
    add_column :companies, :popularity, :integer, :default => 0, :null => false
    add_column :characters, :popularity, :integer, :default => 0, :null => false
  end

  def self.down
    drop_column :movies, :popularity
    drop_column :people, :popularity
    drop_column :companies, :popularity
    drop_column :characters, :popularity
  end
end
