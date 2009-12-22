class ActorAliases < ActiveRecord::Migration
  def self.up
    add_column 'aliases', :actor_id, :integer
    add_index 'aliases', [ :actor_id, :language_id ]
  end

  def self.down
    remove_column 'aliases', :actor_id
  end
end
