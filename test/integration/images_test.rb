require "#{File.dirname(__FILE__)}/../test_helper"

class ImagesTest < ActionController::IntegrationTest
  fixtures :globalize_languages, :movies, :categories, :jobs, :users, :images

  class << PageCacheSweeper.instance
      def expire(path)
        LOGGER.info "Expired page: #{path}"
        ActionController::Base.test_page_expired << path
      end
  end

  def setup
  end
  
  def test_image_versioning
    m = movies(:king_kong)
    assert_nil m.image
    new_session_as users(:quentin), 'test' do |s|
      assert_difference Image, :count do
        assert_difference Image::Version, :count do
          s.multipart_post "/movie/#{m.id}/upload_image", :file => { :data => image_upload('1116.jpeg') },
            :image => { :license => "21", :source => "one" }
        end
      end
      m.reload
      old_img = m.image
      pages = pages_for old_img.id, 'jpeg'
      full_pages = expire_pages_for old_img
      assert_equal 1, old_img.version
      assert_no_difference Image, :count do
        assert_difference Image::Version, :count do
          assert_expire_pages(*full_pages) do |*urls|
            s.multipart_post "/movie/#{m.id}/upload_image", :file => { :data => image_upload('322.jpg') },
              :image => { :license => "12", :source => "two" }
          end
        end
      end
      old_img.reload; m.reload
      assert_equal old_img.id, m.image.id
      assert_equal 2, old_img.versions.size
      assert_equal 2, old_img.version
    end
  end

  def test_image_caching
    new_session_as users(:quentin), 'test' do |s|
      img = create_image 'no_cover.png', 'image/png'
      m = movies(:king_kong)
      m.image = img
      m.save

      pages = pages_for img.id, 'png'
      assert_cache_pages *pages
      full_pages = expire_pages_for img
      assert_expire_pages(*full_pages) do |*urls|
        s.multipart_post "/movie/#{m.id}/upload_image", :file => { :data => image_upload('1116.jpeg') },
          :image => { :license => "12", :source => "http://www.omdb.org/" }
      end
      img.reload
      assert_equal "#{img.id}.jpeg", img.filename

      pages = pages_for img.id, 'jpeg'
      assert_cache_pages *pages
      assert_expire_pages(*full_pages) do |*urls|
        s.multipart_post "/movie/#{m.id}/upload_image", :file => { :data => image_upload('322.jpg') }
      end
      img.reload
      assert_equal "#{img.id}.jpeg", img.filename

      pages = pages_for img.id, 'jpeg'
      assert_cache_pages *pages
      assert_expire_pages(*full_pages) do |*urls|
        s.multipart_post "/movie/#{m.id}/upload_image", :file => { :data => image_upload('1116.jpeg') }
      end

    end
  end

  protected

  def pages_for(id, type)
    [ "/image/", 
      "/image/view/",
      "/image/tiny/",
      "/image/small/",
      "/image/medium/",
      "/image/default/", 
      "/image/wiki/" ].map { |path| "#{path}#{id}.#{type}" } 
  end

  def expire_pages_for(img)
    pages_for(img.id, '*').map { |p| "#{RAILS_ROOT}/public#{p}" }
  end

  def image_upload(name, content_type = 'image/jpeg')
    fixture_file_upload("/images/#{name}", content_type)
  end
    
  def create_image(name, content_type, description = 'image description')
    Image.create! :uploaded_data => image_upload(name, content_type), :license => "12", :source => "http://wwww.omdb.org/", :related_object => movies(:king_kong)
  end

end
