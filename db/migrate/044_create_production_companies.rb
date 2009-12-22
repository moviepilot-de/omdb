class CreateProductionCompanies < ActiveRecord::Migration
  def self.up
    create_table :production_companies do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "company_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 9999, :null => false
      t.column "type", :string, :limit => 64
      t.column "frozen", :boolean, :default => false, :null => false
    end

    add_index "production_companies", ["movie_id"], :name => "movie_id"
    add_index "production_companies", ["company_id"], :name => "company_id"
    add_index "production_companies", ["movie_id", "type"], :name => "movie_and_type"
    add_index "production_companies", ["company_id", "type"], :name => "company_and_type"

    drop_table :movie_companies
  end

  def self.down
    drop_table :production_companies

    create_table "movie_companies", :id => false, :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "company_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 0, :null => false
    end

    add_index "movie_companies", ["company_id"], :name => "company_id"
    add_index "movie_companies", ["movie_id"], :name => "movie_id"
  end
end
