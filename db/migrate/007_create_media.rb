class CreateMedia < ActiveRecord::Migration
  def self.up
    create_table :media do |t|
      t.column "release_id", :integer, :default => 0, :null => false
      t.column "type", :string, :limit => 64
      t.column "name", :string, :limit => 64, :default => "", :null => false
    end

    add_index "media", ["release_id"], :name => "release_id"
  end

  def self.down
    drop_table :media
  end
end
