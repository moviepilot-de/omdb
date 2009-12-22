class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.column "type", :string, :limit => 32, :default => "", :null => false
      t.column "ip", :string, :limit => 16, :default => "", :null => false
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "vote", :integer, :limit => 4, :default => 0, :null => false
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "created_at", :datetime, :null => false
    end

    add_column :movies, :vote, :float, :default => 0.0, :null => false
  end

  def self.down
    drop_table :votes
    remove_column :movies, :vote
  end
end
