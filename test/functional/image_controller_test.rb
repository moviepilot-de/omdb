require File.dirname(__FILE__) + '/../test_helper'
require 'image_controller'

# Re-raise errors caught by the controller.
class ImageController; def rescue_action(e) raise e end; end

class ImageControllerTest < Test::Unit::TestCase
  include Magick
  
  fixtures :images
  
  def setup
    @controller = ImageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_tiny_thumbnail
    get :tiny, :id => images(:image).id
    assert_response :success
    i = Image.from_blob( @response.body )
    assert_equal 45, i.first.columns
  end
  
  def test_small_thumbnail
    get :small, :id => images(:image).id
    assert_response :success
    i = Image.from_blob( @response.body )
    assert_equal 60, i.first.columns
  end

  def test_medium_thumbnail
    get :medium, :id => images(:image).id
    assert_response :success
    i = Image.from_blob( @response.body )
    assert_equal 92, i.first.columns
  end

  def test_wiki_thumbnail
    get :wiki, :id => images(:image).id
    assert_response :success
    i = Image.from_blob( @response.body )
    assert_equal 250, i.first.columns
  end
  
  def test_not_found
    get :tiny
    assert_response 404
  end

#  def test_medium_thumbnail_without_id
#    get :medium
#    assert_response :success
#    assert @response.body.size > 0
#  end

#  def test_get_medium_thumbnail_with_empty_data
#    image = Image.create()
#    get :medium, :id => image.id
#    assert_response :success
#    assert @response.body.size > 0
#  end
end
