require File.dirname(__FILE__) + '/../test_helper'

class AliasTest < Test::Unit::TestCase
  fixtures :name_aliases, :movies, :categories, :jobs

  def test_create_with_movie
    alais = NameAlias.create(:related_object => movies(:king_kong), 
                             :language => Locale.base_language, 
                             :name => "new alias")
    assert_not_nil alais
    assert_nothing_raised { alais.save! }
  end
  
  def test_create_set_type
    alais = NameAlias.create(:related_object => movies(:king_kong), 
                             :language => Locale.base_language, 
                             :name => "new alias")
    alais.save!
    assert_not_nil alais.related_object
    assert_equal "Movie", alais.related_object.class.to_s
  end
  
  def test_related_object
    alais = NameAlias.create(:related_object => movies(:king_kong), 
                             :language => Locale.base_language, 
                             :name => "new alias")
    obj = alais.related_object
    assert_not_nil obj
    assert_equal movies(:king_kong), obj
  end
end
