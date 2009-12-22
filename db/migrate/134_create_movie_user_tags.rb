class CreateMovieUserTags < ActiveRecord::Migration
  def self.up
    create_table :movie_user_tags, :options => 'ENGINE=MyISAM' do |t|
      t.column :user_id, :integer
      t.column :movie_id, :integer
      t.column :tag, :string
    end
    
    add_index :movie_user_tags, [ :user_id, :tag ]
  end

  def self.down
    drop_table :movie_user_tags
  end
end
