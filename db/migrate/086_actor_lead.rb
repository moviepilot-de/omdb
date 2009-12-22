class ActorLead < ActiveRecord::Migration
  def self.up
    add_column :casts, :lead, :boolean, :default => false
  end

  def self.down
    remove_column :casts, :lead
  end
end
