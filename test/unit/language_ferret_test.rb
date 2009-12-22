require File.dirname(__FILE__) + '/../test_helper'

class LanguageFerretTest < Test::Unit::TestCase
  fixtures :globalize_languages, :globalize_translations
  
  def teardown
    Searcher.close!
  end
  
  def test_language_search
    langs = Searcher.search_languages 'en', Locale.base_language.code
    assert langs.collect{|l| l.to_o}.include?( Locale.base_language )
  end
  
end
