class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.column "name", :string, :limit => 128, :default => "", :null => false
    end

    create_table "movie_companies", :id => false, :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "company_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 0, :null => false
    end

    add_index "movie_companies", ["company_id"], :name => "company_id"
    add_index "movie_companies", ["movie_id"], :name => "movie_id"
  end

  def self.down
    drop_table :companies
    drop_table :movie_companies
  end
end
