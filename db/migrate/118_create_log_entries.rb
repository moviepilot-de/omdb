class CreateLogEntries < ActiveRecord::Migration
  def self.up
    create_table :log_entries do |t|
      t.column :attribute, :string, :null => false
      t.column :old_value, :text
      t.column :new_value, :text
      t.column :related_object_type, :string, :null => false
      t.column :related_object_id, :integer, :null => false
      t.column :user_id, :integer
      t.column :ip_address, :string
      t.column :comment, :string
      t.column :created_at, :datetime
      t.column :type, :string
      t.column :reverted, :boolean, :default => false
    end
    
    drop_table :movie_versions rescue nil
    
    Movie.find_all.each do |movie|
      movie.log_entries.create( :attribute => "self", :ip_address => 'unknown', :user => User.anonymous )
    end
  end

  def self.down
    drop_table :log_entries
  end
end
