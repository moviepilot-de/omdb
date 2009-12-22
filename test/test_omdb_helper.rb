module TestOmdbHelper

  def self.included(base) # :nodoc:
    base.extend TestOmdbHelper
  end

  def view_test_for( klass, id, opts = {} )
    options = { :action       => :index, 
    :template     => 'overview.rhtml', 
    :common_template => false,
    :method       => :get,
    :fetch_method => klass.to_s.pluralize,
    :xhr          => false, 
    :params       => {},
    :response     => :success,
    :login        => nil }
    options.update(opts)

    define_method( "test_view_#{options[:action]}_#{id.to_s}#{options[:params].to_s}" ) do
      object = self.send(options[:fetch_method], id)
      login_as options[:login] unless options[:login].nil?
      if options[:xhr] 
        xhr options[:method], options[:action], options[:params].reverse_merge({ :id => object.id })
      else
        self.send( options[:method], options[:action], options[:params].reverse_merge({ :id => object.id }) )
      end
      assert_response options[:response]
      assert_template options[:template] if options[:response] == :success
      assert @response.rendered_file.include?("views/common/") if options[:common_template]
      yield self if block_given?
    end
  end

  def abstract_test_for( klass, id, abstract, options = {} )
    fetch_method = options[:fetch_method] ||= klass.to_s.pluralize
    clazz = options[:klass] ||= klass.to_s.camelize.constantize

    define_method( :test_get_abstract_form ) do
      xhr :post, :set_abstract, :id => self.send(fetch_method, id).id
      assert_success
      assert_template 'set_abstract.rhtml'
      if abstract.nil?
        assert_tag :textarea, :content => ""
      else
        assert_tag :tag => "textarea", :content => contents(abstract).data,
            :attributes => { :id => "#{klass.to_s.downcase}_abstract", :name => "#{klass.to_s}[abstract]" }
      end
    end

    define_method( :test_set_abstract ) do
      abstract = abstract.nil? ? "abcdefgh" : contents(abstract).data.reverse
      xhr :post, :set_abstract, :id => self.send(fetch_method, id).id, klass => { :abstract => abstract }
      assert_success
      assert_equal(abstract, clazz.find( self.send(fetch_method, id).id ).abstract( Locale.base_language ).data)
    end

    define_method( :test_set_empty_abstract ) do
      xhr :post, :set_abstract, :id => self.send(fetch_method, id).id, klass => { :abstract => "" }
      assert_success
      assert_equal("", clazz.find( self.send(fetch_method, id).id ).abstract( Locale.base_language ).data)
    end
    
    define_method( :test_too_long_abstract ) do
      xhr :post, :set_abstract, :id => self.send(fetch_method, id).id, klass => { :abstract => (1..201).collect {"a "}.join }
      assert_success
      assert @response.body.include?("abstract_errors")
    end
  end
  
  def image_test_for( klass, id, opts = {} )
    options = { :fetch_method => klass.to_s.pluralize }
    options.update( opts )

    # Expecting a javascript Redirect (login required)
    view_test_for klass, id, :action => :new_image, :method => :post, :xhr => true, :template => nil, :fetch_method => options[:fetch_method]
    
    # Expecting a redirect to the index page (after successful upload)
    view_test_for klass, id, :action => :new_image, :method => :post, :xhr => true, :fetch_method => options[:fetch_method],
                                 :template => 'new_image.rhtml', :common_template => true, :login => :quentin
                                 
    # Expeting the object to not have an image, but to have one after the upload
    define_method( "test_upload_image_#{klass}_#{id}") do
      login_as :quentin
      object = self.send(options[:fetch_method], id)
      assert_equal nil, object.image
      assert_difference Image, :count do
        post :upload_image, :id => object.id, :image => { :license => "12", :source => "http://www.omdb.org" },
             :file => { :data => fixture_file_upload("/images/no_cover.png", "image/png") },
             :image_summary => "some text"
        assert_redirect
        assert_redirected_to :action => :index
        object.reload
        assert_cookie :dont_cache, :value => "/image/default/#{object.image.id}.png"
      end
      assert !object.image.nil?
    end
    
    define_method( "test_new_image_without_login") do
      object = self.send(options[:fetch_method], id)
      xhr :post, :new_image, :id => object.id
      assert_success
      assert @response.body =~ /\/account\/login/
    end
    
    define_method( "test_upload_without_login") do
      object = self.send(options[:fetch_method], id)
      assert_equal nil, object.image
      assert_no_difference Image, :count do
        post :upload_image, :id => object.id, :image => { :license => "12", :source => "http://www.omdb.org" },
             :file => { :data => fixture_file_upload("/images/no_cover.png", "image/png") },
             :image_summary => "some text"
      end
    end
  end
  
  def edit_aliases_test_for( klass, id, name, opts = {} )
    options = { :fetch_method => klass.to_s.pluralize, :language_independent => false }
    options.update(opts)

    define_method( "test_edit_aliases_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)

      xhr :post, :edit_aliases, :id => object.id
      assert_response :success
      assert_template 'edit_aliases.rhtml'
    end
    
    define_method( "test_create_alias_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)

      xhr :post, :create_alias, :id => object.id, :alias => { :name => name, :language => ( options[:language_independent] ? "1" : Locale.base_language.id ) }
      assert_response :success
      if options[:language_independent]
        assert object.aliases.collect { |a| a.name }.include?( name )
      else
        assert object.aliases.local( Locale.base_language ).collect { |a| a.name }.include?( name )
      end
    end

    # Don't allow the same name/language-combination twice for any object
    define_method( "test_create_alias_twice_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)

      assert_difference NameAlias, :count do
        xhr :post, :create_alias, :id => object.id, :alias => { :name => name, :language => ( options[:language_independent] ? "1" : Locale.base_language.id ) }
        assert_response :success
      end
      assert_no_difference NameAlias, :count do
        xhr :post, :create_alias, :id => object.id, :alias => { :name => name, :language => ( options[:language_independent] ? "1" : Locale.base_language.id ) }
        assert_response :success
      end
    end

    
    define_method( "test_unauthorized_delete_alias_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)
      # create an alias 1st
      assert_difference NameAlias, :count do
        xhr :post, :create_alias, :id => object.id, :alias => { :name => name, :language => ( options[:language_independent] ? "1" : Locale.base_language.id ) }
      end
      name_alias = object.aliases.first
      
      assert_no_difference NameAlias, :count do
        # then try to destroy it
        xhr :post, :destroy_alias, :id => object.id, :alias => name_alias.id
      end
    end
    
    define_method( "test_authorized_delete_alias_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)
      login_as :admin
      # create an alias 1st
      assert_difference NameAlias, :count do
        xhr :post, :create_alias, :id => object.id, :alias => { :name => name, :language => ( options[:language_independent] ? "1" : Locale.base_language.id ) }
      end
      name_alias = object.aliases.first
      
      assert_difference NameAlias, :count, -1 do
        # then try to destroy it
        xhr :post, :destroy_alias, :id => object.id, :alias => name_alias.id
      end
    end
  end
  
  def trackback_test_for( klass, id, opts = {} )
    options = { :fetch_method => klass.to_s.pluralize }
    options.update(opts)
    
    define_method( "test_trackback_post_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)
      title = "blog entry title"
      
      assert_difference TrackBack, :count do
        post :trackback, :id => object.id, :url => "http://wwww.blog.com/some/url", :title => title
        assert_response :success
        xml = REXML::Document.new(@response.body)
        assert_equal "0", REXML::XPath.match(xml, '/response/error').first.text
      end
      assert @controller.has_verified_akismet_key?
      assert_equal title, object.track_backs.last.title
    end
    
    define_method( "test_trackback_get_for_#{klass.to_s}_#{id.to_s}" ) do
      object = self.send(options[:fetch_method], id)
      post :trackback, :id => object.id, :url => "http://wwww.blog.com/some/url", :title => "first"
      post :trackback, :id => object.id, :url => "http://wwww.blog.com/some/url", :title => "second"
      
      get :trackback, :id => object.id
      assert_response :success
      assert_template 'trackbacks.rxml'
      xml = REXML::Document.new(@response.body)
      assert_equal "first", REXML::XPath.match(xml, '/rss/channel/item/title').first.text
    end
  end
  
end
