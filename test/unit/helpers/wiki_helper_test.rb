require File.dirname(__FILE__) + '/../../test_helper'

class WikiHelperTest < HelperTestCase

  include Wiki::WikiHelper
  include ImageHelper

  fixtures :movies, :contents

#  def setup
#    super
#  end
#  
#  def teardown
#    ::Image.delete_all
#  end
#  
#  def test_versions_as_list
#    versions = versions_as_list(10)
#    assert_equal 10, versions.size
#    assert_equal 1, versions.first
#    assert_equal 10, versions.last
#  end
#  
#  def test_render_floating_images
#    upload = fixture_file_upload("/images/no_cover.png", "image/png")
#    image = ::Image.create(:data => upload.read,
#                         :content_type => upload.content_type,
#                         :original_filename => upload.original_filename)
#    image.save!
#    
#    page = contents(:movie_page)
#    page.data << "[[i:#{image.id}]]"
#    rendered = render_floating_images page
#    assert_not_nil rendered
#    assert_match %r{/image/#{image.id}/medium_thumbnail}, rendered
#  end
end
