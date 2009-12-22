require File.dirname(__FILE__) + '/../test_helper'
require 'statistic_controller'

class StatisticController; def rescue_action(e) raise e end; end

class StatisticControllerTest < Test::Unit::TestCase
  include TestOmdbHelper

  fixtures :movies, :movie_countries, :globalize_countries, :categories, 
           :name_aliases, :companies, :production_companies,
	   :movie_user_categories

  set_fixture_class(:globalize_countries=> "Country")

  def setup
    @controller = StatisticController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_country_stats
    get :movies_per_year, :country => globalize_countries(:usa).id
    assert_success
    get :quality_per_year, :country => globalize_countries(:usa).id
    assert_success
  end

  def test_category_stats
    get :movies_per_year, :category => categories(:action).id
    assert_success
    get :quality_per_year, :category => categories(:action).id
    assert_success
  end

  def test_company_status
    get :movies_per_year, :company => companies(:paramount).id
    assert_success
    get :quality_per_year, :company => companies(:paramount).id
    assert_success
  end
end
