class RepairWikiwords < ActiveRecord::Migration
  def self.up
    WikiWordRepair.run
  end

  def self.down
  end
end
