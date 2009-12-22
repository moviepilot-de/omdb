class CastDropCharacterName < ActiveRecord::Migration
  def self.up
    puts "\nConverting all Actors.. this may take a while.."
    counter = 0
    Actor.find_all.each { |a|
      a.comment = a.character_name
      a.save
      counter = counter.next
      if (counter % 100 == 0) then print "." ; $stdout.flush end
    }
    puts ""
    remove_column :casts, :character_name
 
    add_index :casts, [:movie_id, :type], :name => "movie_id_and_type"
    add_index :casts, [:character_id], :name => 'character_id'
  end

  def self.down
    add_column :casts, "character_name", :string, :limit => 100
    puts "\nConverting all Actors.. this may take a while.."
    counter = 1
    Actor.find_all.each { |a|
      a.character_name = a.comment
      a.save
      counter = counter.next
      if (counter % 100 == 0) then print "." ; $stdout.flush end
    }
    puts ""
    remove_index :casts, :name => 'movie_id_and_type'
    remove_index :casts, :name => 'character_id'
  end
end
