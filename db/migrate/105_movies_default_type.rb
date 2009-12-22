class MoviesDefaultType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Migration.execute "ALTER TABLE movies MODIFY COLUMN type VARCHAR(32) DEFAULT 'Movie'"
  end

  def self.down
    ActiveRecord::Migration.execute "ALTER TABLE movies MODIFY COLUMN type VARCHAR(50) DEFAULT NULL"    
  end
end
