class CastComment < ActiveRecord::Migration
  def self.up
    drop_table :cast_comments
    add_column :casts, :comment, :string, :default => "", :limit => 255
    add_column :cast_versions, :comment, :string, :default => "", :limit => 255
  end

  def self.down
    create_table "cast_comments" do |t|
      t.column "cast_id", :integer, :default => 0, :null => false
      t.column "language_id", :integer, :default => 0, :null => false
      t.column "text", :string, :default => "", :null => false
    end
    remove_column :casts, :comment
    remove_column :cast_versions, :comment
  end
end
