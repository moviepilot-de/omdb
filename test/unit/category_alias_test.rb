require File.dirname(__FILE__) + '/../test_helper'

class CategoryAliasTest < Test::Unit::TestCase
  fixtures :name_aliases, :categories
  
  def test_uniqueness
    als = NameAlias.create(:name => "Hallo", :language => Locale.base_language, 
                           :related_object => categories(:action))
    als.save!

    als = NameAlias.create(:name => "Hallo", :language => Locale.base_language, 
                           :related_object => categories(:action))
    assert_raise(ActiveRecord::RecordInvalid) { als.save! }
  end
end
