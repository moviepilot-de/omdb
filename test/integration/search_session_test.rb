require "#{File.dirname(__FILE__)}/../test_helper"

class SearchSessionTest < ActionController::IntegrationTest
  fixtures :movies, :categories, :jobs, :people, :name_aliases, :globalize_languages, :users

  @@indexed = false
  def setup
    return if @@indexed
    Indexer.reindex
    @@indexed = true
  end

   #This is not working because of a rails bug with integrations
   #see http://dev.rubyonrails.org/ticket/4632
   def test_search_tabs
     new_session do |s|
       s.search_for( 'china' )
       assert_match( /#{movies(:in_china_they_eat_dogs).name}/, s.response.body )
       assert_match( /#{people(:china_doll).name}/, s.response.body )
       assert_match( /#{companies(:chinacorp).name}/, s.response.body )
       assert_match( /#{categories(:china).name}/, s.response.body )
       s.goto_search_tab_movies
       assert_match( /#{movies(:in_china_they_eat_dogs).name}/, s.response.body )
       assert_no_match( /#{people(:china_doll).name}/, s.response.body )
       assert_no_match( /#{companies(:chinacorp).name}/, s.response.body )
       assert_no_match( /#{categories(:china).name}/, s.response.body )
       s.goto_search_tab_people
       assert_no_match( /#{movies(:in_china_they_eat_dogs).name}/, s.response.body )
       assert_match( /#{people(:china_doll).name}/, s.response.body )
       assert_no_match( /#{companies(:chinacorp).name}/, s.response.body )
       assert_no_match( /#{categories(:china).name}/, s.response.body )       
       s.goto_search_tab_companies
       assert_no_match( /#{movies(:in_china_they_eat_dogs).name}/, s.response.body )
       assert_no_match( /#{people(:china_doll).name}/, s.response.body )
       assert_match( /#{companies(:chinacorp).name}/, s.response.body )
       assert_no_match( /#{categories(:china).name}/, s.response.body )
       s.goto_search_tab_encyclopedia
       assert_no_match( /#{movies(:in_china_they_eat_dogs).name}/, s.response.body )
       assert_no_match( /#{people(:china_doll).name}/, s.response.body )
       assert_no_match( /#{companies(:chinacorp).name}/, s.response.body )
       assert_match( /#{categories(:china).name}/, s.response.body )
       end
   end

end
