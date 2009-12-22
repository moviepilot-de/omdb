class AddRatingHistory < ActiveRecord::Migration
  def self.up
    create_table "rating_histories" do |t|
      t.column "rating", :float, :default => 0.0
      t.column "type", :string
      t.column "related_object_type", :string
      t.column "related_object_id", :integer
      t.column "start_date", :date
      t.column "end_date", :date
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
    end
  end

  def self.down
    drop_table "rating_histories"
  end
end
