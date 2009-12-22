require File.dirname(__FILE__) + '/../test_helper'

class CoverTest < Test::Unit::TestCase
  fixtures :images, :name_aliases
  
  def test_name_without_alias
    image = ::Image.create
    
    assert_nil image.name
  end
  
  def test_name_with_alias
    image = images(:image)
    assert_equal name_aliases(:image).name, image.name
  end
  
  def test_name_with_empty_description
    image = Image.new(:original_filename => "hossa.gif")
    assert_equal "hossa.gif", image.name
  end

  def test_filetype
    assert_equal 'jpeg', images(:image).filetype
  end

  def test_filename
    assert_equal "1.jpeg", images(:image).filename
  end
end
