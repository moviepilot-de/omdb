class AddGenderToUsers < ActiveRecord::Migration
  def self.up
    # rename_column('votes', 'vote', 'rating')
    # add_column "votes", "related_object_id", :integer
    # add_column "votes", "related_object_type", :string
    # ActiveRecord::Migration.execute "UPDATE votes SET related_object_id = movie_id WHERE movie_id IS NOT NULL"
    # ActiveRecord::Migration.execute "UPDATE votes SET related_object_type = 'Movie' WHERE movie_id IS NOT NULL"
    #add_column "reviews", "vote_id", :integer
    add_column "votes", "updated_at", :datetime, :null => false
    add_column "users", "gender", :integer
  end

  def self.down
    # rename_column('votes', 'rating', 'vote')
    # remove_column "votes", "related_object_id"
    # remove_column "votes", "related_object_type"
    #remove_column "reviews", "vote_id"
    remove_column "votes", "updated_at"
    remove_column "users", "gender"
  end
end
