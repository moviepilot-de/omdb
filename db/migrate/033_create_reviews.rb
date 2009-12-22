class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.column :user_id, :integer, :null => false
      t.column :movie_id, :integer, :null => false
      t.column :data, :text
      t.column :created_at, :timestamp, :null => false
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :reviews
  end
end
