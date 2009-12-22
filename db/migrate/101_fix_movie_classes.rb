class FixMovieClasses < ActiveRecord::Migration
  def self.up
    ActiveRecord::Migration.execute "update movies set type = 'Movie' where type in ('TVMovie', 'ShortMovie');"
  end

  def self.down
  end
end
