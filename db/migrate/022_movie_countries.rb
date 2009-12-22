class MovieCountries < ActiveRecord::Migration
  def self.up
    create_table "movie_countries", :id => false, :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "country_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 999, :null => false
    end
    add_index "movie_countries", ["country_id"], :name => "country_id"
    add_index "movie_countries", ["movie_id"], :name => "movie_id"
  end

  def self.down
    drop table :movie_countries
  end
end
