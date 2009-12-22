require File.dirname(__FILE__) + '/../test_helper'

class ContentTest < Test::Unit::TestCase
  fixtures :contents
  
  def test_save_content_cache_of_version
    page = contents(:first_page)
    page.data << "rev_1"
    page.accept_license_and_save!
    assert_equal 1, page.version
    page.data << " rev_2"
    page.accept_license_and_save!
    assert_equal 2, page.version
    v_1 = page.find_version(1)
    assert_equal 1, v_1.version
    created_at = v_1.created_at
    assert created_at

    sleep 1
    v_1.save_content_cache 'dummy content'
    v_1.reload
    assert_equal created_at, v_1.created_at
  end

  def test_save_content_cache
    page = contents(:first_page)
    assert_nil page.data_html
    assert_nil page.html_updated_at
    assert page.html_needs_update?

    assert_no_difference Content::Version, :count do
      page.save_content_cache '<p>html content</p>'
    end
    page = Page.find(page.id)
    assert_not_nil page.html_updated_at
    assert_equal '<p>html content</p>', page.data_html
    assert !page.html_needs_update?
    Time.mock!(40.minutes.from_now) do
      assert page.html_needs_update?
    end
  end

  def test_version
    page = contents(:first_page)
    page.data << "Whatup doc?"
    page.accept_license = '1'
    page.save
    assert_equal 1, page.version
    page.data << "Nothing"
    page.save
    assert_equal 2, page.version
  end
  
  def test_name_with_no_related_object
    name = contents(:imprint).name
    assert_not_nil name
    assert_equal "Imprint", name
  end
  
  def test_get_version
    page = contents(:existing_movie_page)
    page.accept_license = '1'
    2.times { page.save! }
    
    assert_not_equal page.version, page.get_version(1).version
  end
  
  def test_get_non_existing_version
    page = contents(:existing_movie_page)
    
    assert_same page, page.get_version(10000)
  end
  
  def test_current_version_with_current_version
    page = contents(:existing_movie_page)
    page = page.get_version(page.version)
    assert_equal page.current_version, page.version
  end
  
  def test_current_version_with_older_version
    page = contents(:existing_movie_page)
    page.accept_license = '1'
    3.times { page.save! }
    page = page.get_version(1)
    assert_equal 1, page.version
    assert_equal 3, page.current_version
  end
  
end
