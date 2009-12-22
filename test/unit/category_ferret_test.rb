require File.dirname(__FILE__) + '/../test_helper'

class CategoryFerretTest < Test::Unit::TestCase
  fixtures :categories, :name_aliases, :movies, :globalize_languages

  def teardown
    Searcher.close!
  end

  def test_livesearch
    # should find "Genre > Comedy > Slapstick"
    filtered = Category.search_localized("slap", Locale.base_language)
    assert_equal 1, filtered.size
    assert_equal categories(:slapstick).id, filtered.first.id
  end

  def test_livesearch_hierarchy
    filtered = Category.search_localized("comedy", Locale.base_language)
    assert_equal 17, filtered.size
    assert filtered.collect {|c| c.to_o}.include?( categories(:slapstick) )
  end
  
  def test_reindex_hierarchy
    cat = categories(:action)
    na = cat.aliases.local( Locale.base_language ).first
    na.name = "Noitca"
    assert na.save
    assert_equal "Noitca", cat.reload.local_name( Locale.base_language )
    assert_equal "Noitca > Saving the world", categories(:saving_the_world).flattened_name( Locale.base_language )

    cats = Category.search_localized("Noitca", Locale.base_language)
    assert cats.collect{|o| o.to_o }.include?( categories(:saving_the_world) )
  end
  
  def test_search_localized
    c = categories(:secret_identity)
    results = Category.search_localized_by_type( Category.plot_keyword.id, 'secr', Locale.base_language )
    assert results.collect{|o| o.to_o}.include?( c )
    results = Category.search_localized_by_type( Category.plot_keyword.id, 'gehe', Language.pick('de') )
    assert results.collect{|o| o.to_o}.include?( c )
    results = Category.search_localized_by_type( Category.genre.id, 'secr', Locale.base_language )
    assert !results.collect{|o| o.to_o}.include?( c )
  end
  
  def test_popular_categories
    results = Searcher.popular_categories_by_type( Category.genre.id )
    assert_equal categories(:martial_arts).id, results.to_a.first.id
  end

  def test_livesearch_umlaut
    filtered = Category.search_localized("verschw", globalize_languages(:german))
    assert filtered.collect{|c| c.to_o}.include?( categories(:conspiracy) )
    filtered = Category.search_localized("verschwö", globalize_languages(:german))
    assert filtered.collect{|c| c.to_o}.include?( categories(:conspiracy) )
  end

  def test_create_alias
    cat = categories(:slapstick)
    assert Category.search_localized("slapstick", Language.pick('en')).collect{|c| c.to_o}.include?( cat )
    cat.aliases << NameAlias.new( :language => Language.pick('en'), :name => "slapstick".reverse )
    cat.save
    assert Category.search_localized("slapstick", Language.pick('en')).collect{|c| c.to_o}.include?( cat )    
    assert Category.search_localized("slapstick".reverse, Language.pick('en')).collect{|c| c.to_o}.include?( cat )    
  end
end
