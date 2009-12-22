class CreateAliases < ActiveRecord::Migration
  def self.up
    drop_table :category_aliases
    drop_table :movie_aliases
    drop_table :person_aliases

    create_table :aliases do |t|
      t.column :name, :string
      t.column :category_id, :integer
      t.column :movie_id, :integer
      t.column :person_id, :integer
      t.column :language_id, :integer
      t.column :position, :integer, :default => 9999
      t.column :alias_type, :string
    end
  end

  def self.down
    drop_table :aliases
    
    create_table "movie_aliases", :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "description", :string, :limit => 100
      t.column "language_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 0
      t.column "frozen", :boolean, :default => false, :null => false
    end

    create_table "category_aliases", :force => true do |t|
      t.column "name", :string
      t.column "language_id", :integer
      t.column "category_id", :integer, :default => 0, :null => false
    end

    create_table "person_aliases", :force => true do |t|
      t.column "person_id", :integer, :default => 0, :null => false
      t.column "name", :string, :default => "", :null => false
      t.column "position", :integer
    end
  end
end
