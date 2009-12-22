class NewTrailer < ActiveRecord::Migration
  def self.up
    create_table :trailers, :force => true do |t|
      t.column :key, :string, :null => false
      t.column :source, :string, :null => false, :default => 'youtube'
      t.column :movie_id, :integer, :null => false
      t.column :language_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :trailers
  end
end