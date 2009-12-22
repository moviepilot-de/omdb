require File.dirname(__FILE__) + '/../test_helper'

class LanguageTest < Test::Unit::TestCase
  fixtures :globalize_languages, :globalize_translations
  
  def test_language_aliases
    names = Language.pick("de").alias_names_by_language
    assert_equal ['German'], names[Language.pick("en")]
    assert_equal ['Deutsch'], names[Language.pick("de")]
  end
end
