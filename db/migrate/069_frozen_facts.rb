class FrozenFacts < ActiveRecord::Migration
  def self.up
    create_table :frozen_attributes, :id => false, :options => 'DEFAULT CHARSET latin1' do |t|
      t.column :object_type, :string, :null => false
      t.column :object_id, :integer, :null => false
      t.column :attribute, :string, :null => false
    end

    add_index :frozen_attributes, [ :object_type, :object_id, :attribute ]
  end

  def self.down
    drop_table :frozen_attributes
  end
end
