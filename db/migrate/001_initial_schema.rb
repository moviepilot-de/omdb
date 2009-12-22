class InitialSchema < ActiveRecord::Migration
  def self.up
      create_table "actions", :force => true do |t|
        t.column "parent_id", :integer
        t.column "name", :string, :limit => 100, :default => "", :null => false
        t.column "controller", :string, :limit => 100, :default => "", :null => false
        t.column "action", :string
        t.column "view", :string, :limit => 100
        t.column "type", :string, :limit => 100
        t.column "success_id", :integer
        t.column "updates", :string, :limit => 50
        t.column "confirmation", :string, :limit => 50
      end

      create_table "cast_comments", :force => true do |t|
        t.column "cast_id", :integer, :default => 0, :null => false
        t.column "language_id", :integer, :default => 0, :null => false
        t.column "text", :string, :default => "", :null => false
      end

      create_table "casts", :force => true do |t|
        t.column "movie_id", :integer, :default => 0, :null => false
        t.column "person_id", :integer, :default => 0, :null => false
        t.column "position", :integer, :default => 999, :null => false
        t.column "type", :string, :limit => 64
        t.column "character_name", :string, :limit => 100
        t.column "character_id", :integer, :default => 0
        t.column "frozen", :boolean, :default => false, :null => false
      end

      add_index "casts", ["movie_id"], :name => "movie_id"
      add_index "casts", ["type"], :name => "type"
      add_index "casts", ["person_id"], :name => "person_id"
      add_index "casts", ["type"], :name => "type_2"

      create_table "characters", :force => true do |t|
        t.column "name", :string, :limit => 100, :default => "", :null => false
      end

      create_table "contents", :force => true do |t|
        t.column "movie_id", :integer, :default => 0, :null => false
        t.column "person_id", :integer, :default => 0, :null => false
        t.column "language_id", :integer, :default => 0, :null => false
        t.column "data", :text, :default => "", :null => false
        t.column "page_name", :string, :limit => 100, :default => "", :null => false
        t.column "type", :string, :limit => 50
        t.column "name", :string, :limit => 100
      end

      create_table "genres", :force => true do |t|
        t.column "parent_id", :integer
        t.column "name", :string, :limit => 200, :default => "", :null => false
        t.column "position", :integer, :default => 0
        t.column "example_movie1", :integer
        t.column "example_movie2", :integer
        t.column "example_movie3", :integer
      end

      create_table "genres_movies", :id => false, :force => true do |t|
        t.column "movie_id", :integer, :default => 0, :null => false
        t.column "genre_id", :integer, :default => 0, :null => false
      end

      create_table "languages", :force => true do |t|
        t.column "code", :string, :limit => 2, :default => "", :null => false
        t.column "active", :boolean, :default => false, :null => false
      end

      create_table "movie_aliases", :force => true do |t|
        t.column "movie_id", :integer, :default => 0, :null => false
        t.column "name", :string, :limit => 100, :default => "", :null => false
        t.column "description", :string, :limit => 100
        t.column "language_id", :integer, :default => 0, :null => false
        t.column "position", :integer, :default => 0
      end

      create_table "movie_contents", :force => true do |t|
        t.column "movie_id", :integer, :default => 0, :null => false
        t.column "language_id", :integer, :default => 0, :null => false
        t.column "data", :text, :default => "", :null => false
      end

      create_table "movie_languages", :id => false, :force => true do |t|
        t.column "movie_id", :integer, :default => 0, :null => false
        t.column "language_id", :integer, :default => 0, :null => false
      end

      create_table "movies", :force => true do |t|
        t.column "parent_id", :integer
        t.column "name", :string, :limit => 100, :default => "", :null => false
        t.column "type", :string, :limit => 50
        t.column "start", :date
        t.column "end", :date, :null => false
        t.column "runtime", :integer, :default => 0, :null => false
        t.column "inherit_cast", :boolean, :default => false, :null => false
        t.column "inherit_genres", :boolean, :default => false, :null => false
        t.column "position", :integer
      end

      create_table "people", :force => true do |t|
        t.column "name", :string, :limit => 100, :default => "", :null => false
        t.column "birthday", :date
        t.column "is_actor", :boolean, :default => false, :null => false
        t.column "is_director", :boolean, :default => false, :null => false
        t.column "is_author", :boolean, :default => false, :null => false
      end

      add_index "people", ["name"], :name => "name"

      create_table "person_aliases", :force => true do |t|
        t.column "person_id", :integer, :default => 0, :null => false
        t.column "name", :string, :default => "", :null => false
        t.column "position", :integer
      end

      create_table "popularities", :force => true do |t|
        t.column "created_at", :datetime, :null => false
        t.column "for_type", :string, :limit => 50, :default => "", :null => false
        t.column "for_id", :integer, :default => 0, :null => false
        t.column "language_id", :integer, :default => 0, :null => false
      end
  end

  def self.down
  end
end
