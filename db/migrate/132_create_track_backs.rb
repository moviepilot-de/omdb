class CreateTrackBacks < ActiveRecord::Migration
  def self.up
    create_table :track_backs do |t|
      t.column :url, :string, :null => false
      t.column :title, :string
      t.column :excerpt, :string
      t.column :blog_name, :string
      t.column :language_id, :integer
      t.column :is_spam, :boolean, :default => false
      t.column :tracked_object_type, :string, :null => false
      t.column :tracked_object_id, :integer, :null => false
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :track_backs
  end
end
