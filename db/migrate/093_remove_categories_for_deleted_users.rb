class RemoveCategoriesForDeletedUsers < ActiveRecord::Migration
  def self.up
    old_votes = MovieUserCategory.find_by_sql("SELECT * FROM movie_user_categories as mvc WHERE NOT EXISTS (SELECT * FROM users WHERE mvc.user_id = users.id)")
    if not old_votes.nil?
      old_votes.each do |v|
        v.destroy
      end
    end
  end

  def self.down
  end
end
