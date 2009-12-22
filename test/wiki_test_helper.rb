module WikiTestHelper
  def self.included(base) # :nodoc:
    base.extend ClassMethods
  end

  module ClassMethods

    # these tests require an object with several existing pages in the default
    # language:
    # 'Additional Page 1' and 'index'
    # in addition, a page named 'New Page' must not exist.
    def view_page_tests_for(sym, id, options = {}) 
      name = sym.to_s
      fixtures = name.pluralize.to_sym
      clazz = name.camelize.constantize

      define_method :"test_handle_overview_requests_#{name}_#{id}" do
        obj = send(fixtures, id)
        get :overview, :id => obj.id
        assert_response 301
        assert_redirected_to :action => 'index'
      end

      # view the toc
      define_method :"test_view_toc_#{name}_#{id}" do
        obj = send(fixtures, id)
        get :page, :id => obj.id
        assert_response :success
        assert_template 'toc.rhtml'
        # we want no index page in toc
        assert_no_tag :tag => "a",
                   :content => "more",
                   :attributes => { :href => %r{/#{name}/#{obj.id}/page/index} }
        assert_tag :tag => "a",
                   :content => "more".t,
                   :attributes => { :href => %r{/#{name}/#{obj.id}/page/Additional\+Page\+1} }
      end

      # view a page
      define_method :"test_view_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        get :page, :id => obj.id, :page => 'Additional Page 1'
        assert_response :success
        assert_equal obj, assigns(:page).related_object
        assert_template 'page.rhtml'
        if options[:readonly] # no edit link if we aren't allowed to edit the page
          assert_no_tag :tag => "a",
                        :content => "edit article",
                        :attributes => { :href => %r{/#{name}/#{obj.id}/edit_page/Additional\+Page\+1} } 
        else
          assert_tag :tag => "a",
                    :content => "edit article",
                    :attributes => { :href => %r{/#{name}/#{obj.id}/edit_page/Additional\+Page\+1} } 
        end
      end

      define_method :"test_view_nonexisting_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        get :page, :id => obj.id, :page => 'my_non_existing_page'

        unless options[:readonly]
          assert_tag 'a', :content => 'create article',
                          :attributes => { :href => %r{/#{name}/#{obj.id}/edit_page/my_non_existing_page} } 
        end
        assert_response :missing
      end

      # page preview
      define_method :"test_preview_#{name}_#{id}" do
        obj = send(fixtures, id)
        page = obj.pages.find_by_page_name('Additional Page 1')
        xhr :post, :preview, :id => obj.id, :page => 'Additional Page 1',
                   :edited_page => { :data => 'new content: [[WikiWiki]]' }
        assert_response :success
        assert_rjs :replace_html, 'wiki-preview'
        assert_match  %r(<p>new content: <a href=.+#{obj.id}/page/WikiWiki.+>.*WikiWiki</a></p>), @response.body
        #assert_nil Page.find(page.id).data_html # preview should not set cache
      end

      define_method :"test_view_changelog_#{name}_#{id}" do
        obj = send(fixtures, id)
        get :changelog, :id => obj.id, :page => 'Additional Page 1'
        assert_response :success
      end

    end

    # renaming of pages
    def rename_page_tests_for(sym, id, options = {}) 
      name = sym.to_s
      fixtures = name.pluralize.to_sym
      clazz = name.camelize.constantize

      # show rename page dialog
      define_method :"test_rename_index_page_xhr_#{name}_#{id}" do
        obj = send(fixtures, id)
        xhr :post, :rename_page, :id => obj.id, :page => 'index'
        assert_access_denied_xhr

        login_as :admin
        xhr :post, :rename_page, :id => obj.id, :page => 'index'
        assert_response :success
        assert_tag 'div', :attributes => { :class => 'error' }
        assert_match %r{Can't rename index page}, @response.body

        xhr :post, :rename_page, :id => obj.id, :page => 'index', :edited_page => { :page_name => 'newname' }
        assert_response :success
        assert_rjs :replace_html, 'error-messages', %{<div class="error">Can't rename index page</div>}
      end

      define_method :"test_rename_other_page_xhr_#{name}_#{id}" do
        obj = send(fixtures, id)
        xhr :post, :rename_page, :id => obj.id, :page => 'Additional Page 1'
        assert_access_denied_xhr

        login_as :admin
        xhr :post, :rename_page, :id => obj.id, :page => 'Additional Page 1'
        assert_response :success

        xhr :post, :rename_page, :id => obj.id, :page => 'Additional Page 1',
                                 :edited_page => { :page_name => 'newname' }
        assert_response :success
        assert_rjs :call, 'box.deactivate'
        assert_rjs :redirect, :action => 'page', :page => 'newname'
        assert obj.pages.find_by_page_name('newname')
      end


    end

    # write access to pages, same pre conditions as view_page_test_for
    def write_page_tests_for(sym, id, options = {}) 
      name = sym.to_s
      fixtures = name.pluralize.to_sym
      clazz = name.camelize.constantize

      # show new page dialog
      define_method :"test_create_new_page_dialog_xhr_#{name}_#{id}" do
        obj = send(fixtures, id)
        xhr :post, :new_page, :id => obj.id
        if options[:readonly]
          assert_access_denied_xhr
          return unless options[:login_as]
          login_as options[:login_as]
          xhr :post, :new_page, :id => obj.id
        end
        assert_response :success
      end

      # create a new page
      define_method :"test_create_new_movie_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        assert_difference Page, :count, options[:readonly] ? 0 : 1 do
          xhr :post, :create_page, :id => obj.id, :new_page => { :page_name => "New Page" }
        end
        if options[:readonly]
          assert_access_denied_xhr
          return unless options[:login_as]
          login_as options[:login_as]
          assert_difference Page, :count do
            xhr :post, :create_page, :id => obj.id, :new_page => { :page_name => "New Page" }
          end
        end

        assert_response :success
        assert_rjs :redirect, :action => 'page', :id => obj.id, :page => 'New Page'
        new_page = obj.pages.find_by_name('New Page')
        assert new_page
        assert new_page.creator
        assert_equal new_page.creator, new_page.user
        assert_equal (options[:login_as] ? self.send( fixtures, id) : User.anonymous), new_page.creator

        # create the same page again, this time plain http, should fail:
        assert_no_difference Page, :count do
          post :create_page, :id => obj.id, :new_page => { :page_name => 'New Page' }
        end
        assert_response :success
        assert_template '_new_page_form.rhtml'
        assert assigns(:new_page).errors.on(:page_name)
        assert_match /that page name is already taken/i, @response.body


        assert_difference Page, :count do
          post :create_page, :id => obj.id, :new_page => { :page_name => 'another new page' }
          assert_redirected_to :action => 'page', :id => obj.id, :page => 'another new page'
        end
      end
      
      # creation of a new page with a strange name
      define_method :"test_create_page_with_invalid_name_#{name}_#{id}" do
        obj = send(fixtures, id)
        post :create_page, :id => obj.id, :new_page => { :page_name => 'new?page' } 
        if options[:readonly]
          assert_access_denied
          return unless options[:login_as]
          login_as options[:login_as]
          post :create_page, :id => obj.id, :new_page => { :page_name => 'new?page' } 
        end
        assert_response :success
        assert assigns(:new_page).errors.on(:page_name)
      end

      # show edit form for a non-existing page
      define_method :"test_edit_nonexisting_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        get :edit_page, :id => obj.id, :page => 'i dont exist (yet)'
        if options[:readonly]
          assert_access_denied
          return unless options[:login_as]
          login_as options[:login_as]
          get :edit_page, :id => obj.id, :page => 'i dont exist (yet)'
        end
        assert_response :success
        assert_template 'edit.rhtml'
        assert assigns(:page)
      end

      # implicit creation of a new page
      define_method :"test_update_nonexisting_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        post :update_page, :id => obj.id, :page => 'New Page', 
                           :edited_page => { :data => 'new page content', 
                                             :accept_license => '1' }
        if options[:readonly]
          assert_access_denied
          return unless options[:login_as]
          login_as options[:login_as]
          post :update_page, :id => obj.id, :page => 'New Page', :edited_page => { 
                      :data => 'new page content', :accept_license => '1'
                    } 
        end
        assert_redirected_to :action => 'page'
        assert_equal 'new page content', obj.pages.find_by_page_name('New Page').data
      end

      # show edit form for a page
      define_method :"test_edit_existing_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        page = obj.pages.find_by_page_name('Additional Page 1')
        get :edit_page, :id => obj.id, :page => 'Additional Page 1'
        if options[:readonly]
          assert_access_denied
          return unless options[:login_as]
          login_as options[:login_as]
          get :edit_page, :id => obj.id, :page => 'Additional Page 1'
        end
        assert_response :success
        assert_template 'edit.rhtml'
        assert assigns(:page)
        assert_tag :tag => "textarea", :content => page.data
      end

      # update a page, includes some html-cache testing
      define_method :"test_update_existing_page_#{name}_#{id}" do
        obj = send(fixtures, id)
        page = obj.pages.find_by_page_name('Additional Page 1')
        get :page, :page => page.page_name, :id => obj.id # for cache testing later on...
        page = Page.find(page.id)
        #assert_match %r{#{page.data}}, page.data_html # cache filled
        
        post :update_page, :id => obj.id, :page => 'Additional Page 1', :edited_page => { 
                    :data => 'new page content'
                  }
      if options[:readonly]
        assert_access_denied
        return unless options[:login_as]
        login_as options[:login_as]
        post :update_page, :id => obj.id, :page => 'Additional Page 1', :edited_page => { 
                      :data => 'new page content'
                    }
        end
        # forgot to check the 'accept license' checkbox...
        assert_response :success
        assert_template 'edit.rhtml'
        assert assigns(:page).errors.on(:accept_license)
        assert_equal 'new page content', assigns(:edited_page).data
        assert_tag :tag => 'textarea', :content => 'new page content'

        # but this time!
        post :update_page, :id => obj.id, :page => 'Additional Page 1', :edited_page => { 
                    :data => 'new page content...', :accept_license => '1'
                  }
        assert_redirected_to :action => 'page'
        if obj.class.controller_name =~ ENCYCLOPEDIA_CONTROLLERS
          assert_cookie :dont_cache, :value => "/encyclopedia/#{obj.class.controller_name}/#{obj.id}/page/Additional+Page+1"
        else
          assert_cookie :dont_cache, :value => "/#{obj.class.controller_name}/#{obj.id}/page/Additional+Page+1"
        end
        updated_page = Page.find(page.id)
        assert_equal 'new page content...', updated_page.data
        #assert_nil updated_page.data_html # cache empty now

        # cache should get updated after first access to the new version:
        #get :page, :page => page.page_name, :id => obj.id
        #updated_page = Page.find(page.id)
        #assert_equal "<p>#{updated_page.data.gsub '...','&#8230;'}</p>", updated_page.data_html

        
        # update again, to check cache flushing on subsequent edits
        new_content = 'even more new content and a [[link]].'
        old_rev = updated_page.version
        post :update_page, :id => obj.id, :page => 'Additional Page 1', :edited_page => { 
                    :data => new_content, :accept_license => '1'
                  }
        assert_redirected_to :action => 'page'
        updated_page = Page.find(page.id)
        assert_equal new_content, updated_page.data
        #assert_nil updated_page.data_html # cache empty now

        new_rev = updated_page.version
        assert_equal old_rev+1, new_rev

        # cache should get updated after first access to the new version:
        get :page, :page => page.page_name, :id => obj.id
        updated_page = Page.find(page.id)
        #assert_match %r{<p>even more new content and a <a href="/#{'encyclopedia/' if name =~ ENCYCLOPEDIA_CONTROLLERS}#{name}/#{obj.id}/page/link" class="edit">.*link</a>.</p>}, updated_page.data_html
        assert_equal new_content, updated_page.data # data unchanged, only the cache has been updated
        assert_equal new_rev, updated_page.version  # no new version when only the cache is updated
      end

    end

    def page_destruction_tests_for(sym, id, options = {}) 
      name = sym.to_s
      fixtures = name.pluralize.to_sym
      clazz = name.camelize.constantize
      # Seite loeschen
      define_method :"test_destroy_page_requires_admin" do
        obj = send(fixtures, id)
        post :destroy_page, :id => obj.id, :page => 'Additional Page 1'
        assert_access_denied
        login_as :editor
        post :destroy_page, :id => obj.id, :page => 'Additional Page 1'
        assert_access_denied
      end

      define_method :"test_destroy_index_not_allowed" do
        obj = send(fixtures, id)
        login_as :admin
        assert_no_difference Page, :count do
          post :destroy_page, :id => obj.id, :page => 'index'
        end
        (obj.class == User) ? assert_redirected_to( :action => 'index', :id => obj.permalink ) : assert_redirected_to( :action => 'index', :id => obj.id )
      end

      define_method :"test_destroy_page" do
        obj = send(fixtures, id)
        login_as :admin
        assert_difference Page, :count, -1 do
          post :destroy_page, :id => obj.id, :page => 'Additional Page 1'
        end
        (obj.class == User) ? assert_redirected_to( :action => 'index', :id => obj.permalink ) : assert_redirected_to( :action => 'index', :id => obj.id )
      end
    end

    # these test cases require an object without any existing pages (esp. no
    # index pages)
    def index_page_tests_for(sym, id, options = {}) 
      name = sym.to_s
      fixtures = name.pluralize.to_sym
      clazz = name.camelize.constantize

      define_method :"test_index_page_should_be_created_only_first_time_#{name}_#{id}" do
        obj = send(fixtures, id)
        assert_difference Page, :count do
          get :index, :id => obj.id
        end
        assert_no_difference Page, :count do
          get :index, :id => obj.id
        end
        p = Page.find :first, 
                      :conditions => ["related_object_id=? and related_object_type=?", 
                                      obj.id, clazz.name]
        assert p
        assert_equal obj, p.related_object
      end

    end

    def page_versioning_tests_for(sym, id, options = {})
      name = sym.to_s
      fixtures = name.pluralize.to_sym
      clazz = name.camelize.constantize

      define_method :"test_earlier_version_#{name}_#{id}" do
        obj = send(fixtures, id)
        # bump to next version
        page = obj.pages.find_by_page_name 'Additional Page 1'
        page.accept_license_and_save! # create first version (should be in fixtures?)
        page.data << "Updated!"
        page.accept_license_and_save!
        assert_equal 2, page.version

        get :page, :id => obj.id, :rev => 1, :page => 'Additional Page 1'
        assert_equal 1, assigns(:page).version
        assert_no_match /Updated/, @response.body

        get :page, :id => obj.id, :page => 'Additional Page 1'
        assert_match /Updated/, @response.body
        assert_equal 2, assigns(:page).version
      end

      define_method :"test_get_nonexisting_version_#{name}_#{id}" do
        obj = send(fixtures, id)
        page = obj.pages.find_by_page_name 'Additional Page 1'
        page.accept_license_and_save! # create first version (should be in fixtures?)
        get :page, :id => obj.id, :rev => 10, :page => 'Additional Page 1'
        assert assigns(:page)
        assert_equal 1, assigns(:page).version
        get :page, :id => obj.id, :rev => 'affe', :page => 'Additional Page 1'
        assert assigns(:page)
        assert_equal 1, assigns(:page).version
      end

      define_method :"test_history_links_#{name}_#{id}" do
        obj = send(fixtures, id)
        page = obj.pages.find_by_page_name 'Additional Page 1'
        3.times { page.accept_license_and_save! }

        # current rev
        get :page, :id => obj.id, :page => 'Additional Page 1'
        
        # :TODO: fix me .. the history links need to be included in the
        # history-log, including diff/rollback/etc. there're no 
        # links at the bottom of the page anymore. Maybe we should add
        # these links again if viewing an old version.
        return
        assert_tag :tag => "a", :content => "Back in time".t
        assert_tag :tag => "a", :content => "Diff to previous".t
        assert_no_tag :tag => "a", :content => "Rollback".t
        assert_no_tag :tag => "a", :content => "Forward in time".t
        assert_no_tag :tag => "a", :content => "Diff to next".t

        # first rev
        get :page, :id => obj.id, :rev => '1', :page => 'Additional Page 1'
        assert_no_tag :tag => "a", :content => "Back in time".t
        assert_no_tag :tag => "a", :content => "Diff to previous".t
        assert_tag :tag => "a", :content => "Rollback".t
        assert_tag :tag => "a", :content => "Forward in time".t
        assert_tag :tag => "a", :content => "Diff to next".t

        # somewhere in the middle...
        get :page, :id => obj.id, :rev => '2', :page => 'Additional Page 1'
        assert_tag :tag => "a", :content => "Back in time".t
        assert_tag :tag => "a", :content => "Diff to previous".t
        assert_tag :tag => "a", :content => "Rollback".t
        assert_tag :tag => "a", :content => "Forward in time".t
        assert_tag :tag => "a", :content => "Diff to next".t
      end

      # the rollback feature ist implemented as 'edit that old revision'.
      # on save a new revision with the (possibly edited) old content is
      # created.
      define_method :"test_edit_with_revision_#{name}_#{id}" do
        obj = send(fixtures, id)
        page = obj.pages.find_by_page_name 'Additional Page 1'
        old_content = page.data
        page.accept_license_and_save! # create first version (should be in fixtures?)
        page.data = "Updated!"
        page.accept_license_and_save!

        get :edit_page, :id => obj.id, :page => 'Additional Page 1', :rev => 1
        assert_response :success
        assert_tag :tag => "textarea", :content => old_content
        assert_no_tag :tag => "textarea", :content => page.data
      end unless options[:readonly] 
    end

    def rss_link_tests_for(sym, id)
#      name = sym.to_s
#      fixtures = name.pluralize.to_sym
#      clazz = name.camelize.constantize
#
#      # TODO atm there is no RSS link on the index page, when called with
#      # /movie/123
#      #define_method :"test_rss_link_on_index_page_#{name}_#{id}" do
#      #  obj = send(fixtures, id)
#      #  get :index, :id => obj.id
#      #  assert_response :success
#      #  assert_tag :tag => "link", 
#      #             :attributes => { :href => %r{/#{name}/#{obj.id}/rss} }
#      #
#      #end
#      
#      define_method :"test_rss_link_on_toc_#{name}_#{id}" do
#        obj = send(fixtures, id)
#        get :page, :id => obj.id
#        assert_response :success
#        assert_tag :tag => "link", 
#                   :attributes => { :href => %r{/#{name}/#{obj.id}/rss} }
#      end
#
#      define_method :"test_rss_link_on_additional_page_#{name}_#{id}" do
#        obj = send(fixtures, id)
#        get :page, :id => obj.id, :page => 'Additional Page 1'
#        assert_response :success
#        assert_tag :tag => "link", 
#                   :attributes => { :href => %r{/#{name}/#{obj.id}/rss/Additional\+Page\+1} }
#      end
#
    end

  end
end
