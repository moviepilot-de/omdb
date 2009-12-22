module CharacterHelper
  def find_casts
    Cast.find(:all,
              :conditions => [ "character_name like ? AND 
                                character_id = 0      AND 
                                frozen = 0" ,
                               @character.name ] )
  end

  def add_ids(action, character, other_character)
    action[:url].merge!({:id => character.id, :character => other_character.id})
    action
  end
  
  def add_ajax_ids(action, character, other_character)
    action[:ajax_options][:url].merge!({:id => character.id, :character => other_character.id})
    action
  end
  
end
