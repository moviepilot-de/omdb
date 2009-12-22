# common functionality for all controllers serving wiki-like pages
#
# controllers including this module have to implement:
# #related_object - returns the object the pages belong to (a movie, person, user, ...)
#                   this method is made a helper_method automatically upon
#                   inclusion of the module
# #register_tabs  - called as a before_filter
#
# The following views have to be present in the controller's view directory:
# portal/index  - shown when no related_object can be found and the index action is 
#                 called (maybe move this up one directory level ?
# overview      - rendered by index action if related_object is present
# _header       - partial for the header
# _page_actions - partial for Page-related actions (edit, destroy)
# 
module PageActions
  include PageHelper
 
  def self.included(base)
    base.before_filter :find_page, :only => [ :page, :edit_page, :update_page, :changelog,
                                              :preview, :view_diff, :destroy_page, :rename_page ]
    base.before_filter :register_tabs_unless_xhr, :except => [ :my_profile, :add_movie, :delete_movie ]
    base.before_filter :admin_only, :only => [ :rename_page, :destroy_page ]
    base.verify :method => :post, :only => [ :destroy_page, :update_page ]
    base.helper 'page'
    base.helper_method :related_object
    base.cache_sweeper :content_log_observer
  end

  def index
    render :action => 'portal/index' and return unless related_object
    @page     = related_object.wiki_index @language
    @abstract = related_object.abstract   @language if related_object.respond_to?(:abstracts)
    render :action => 'overview' 
  end

  def overview
    redirect_to :action => 'index'
    # unschoen, aber momentan nicht zu aendern, siehe http://dev.rubyonrails.org/ticket/2649
    headers['Status'] = '301 Moved Permanently'
  end

  def new_page
    respond_to do |wants|
      wants.js { render :template => 'page/new_page' }
      wants.html { redirect_to :action => 'index', :page => nil }
    end
  end

  def create_page
    pname = params[:new_page][:page_name] rescue nil
    @new_page = Page.new(:language => @language, :page_name => pname, :name => pname, :related_object => related_object, :user => current_user, :creator => current_user)
    @new_page.accept_license_and_save!

    target_url = page_url @new_page
    respond_to do |wants|
      wants.html { redirect_to target_url }
      wants.js   { render(:update) { |page| page.redirect_to target_url } }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |wants|
      wants.js   { render :update do |page|
                     page.replace_html 'lbform', :partial => 'page/new_page_form'
                   end
      }
      wants.html { render :template => 'page/new_page' }
    end
  end
  
  def page
    if @page
      render :template => 'page/page', :status => ( @page.new_record? ? 404 : 200 )
    elsif params[:page].to_s.blank?
      render :template => 'page/toc'
    else
      render :template => 'error/404', :status => 404 
    end
  end

  def edit_page
    if @page
      if params[:rev] # take content from given revision (the 'Rollback' link)
        data = @page.data
        @page = @page.current
        @page.data = data
      end
    else
      # edit a page that does not exist yet
      @page = new_page_object
    end
    render :template => 'page/edit'
  end

  def update_page
    @page ||= new_page_object
    if @page.update_attributes(params[:edited_page].merge(:user => current_user))
      redirect_to url_for_page('page', @page).merge( :dontcache => @page ) # and return
    else
      flash.now[:error] = 'There were problems saving the page. Please check your input.'.t
      logger.warn @page.errors.full_messages.join("\n")
      @edited_page = @page # for validation message display
      render :template => 'page/edit'
    end
  end

  def preview
    data = params[:edited_page][:data] rescue ''
    render :update do |page|
      page.show 'wiki-preview'
      page.replace_html('wiki-preview', render_wiki_content(:data => data, :content => @page))
    end
  end

  def changelog
    @versions = @page.versions
    render :template => 'page/changelog'
  end

  def view_diff
    @from = params[:from].to_i
    @to   = params[:to].to_i
    @to, @from = @from, @to if @to < @from
    @version1 = @page.find_version(@from)
    @version2 = @page.find_version(@to)
    if @version1 && @version2
      render :template => 'page/diff'
    else 
      handle_404
    end
  end

  def destroy_page
    if @page.page_name == 'index'
      flash[:error] = "Can't delete index page".t
    else
      @page.destroy
    end
    redirect_to( Page === related_object ? '/' : related_object.default_url )
  end

  def rename_page
    if @page.new_record?
      flash.now[:errors] = "Can't rename new page".t
    elsif @page.page_name == 'index'
      flash.now[:errors] = "Can't rename index page".t
    else
      if params[:edited_page]
        @page.page_name = params[:edited_page][:page_name]
        begin
          @page.accept_license_and_save!
        rescue ActiveRecord::RecordInvalid
        end
      end
    end

    if params[:edited_page]
      render :update do |page|
        if @page.errors.any?
          page.replace_html "error-messages", error_messages(:page)
        elsif flash[:errors]
          page.replace_html "error-messages", show_errors
        else
          page.call "box.deactivate"
          page.redirect_to related_object.default_url(@page.page_name)
        end
      end
    else
      render :template => 'page/rename_page'
    end
  end

  # TODO check if rss for a single page is useful, atm all pages for an object
  # have the discovery link pointing to the 'whole object feed' showing changes
  # in all pages
  # TODO limit feed to a reasonable number of versions (10, 15, 20?)
  def rss
    find_page 
    if @page && @page.generic?
      @versions = @page.versions
    else
      @versions = related_object.latest_content_versions
    end
    @object = related_object
    render :template => "page/rss"
  end


  protected

    def find_page
      if Page === related_object
        @page = related_object
      elsif !params[:page].blank?
        @page = related_object.page(params[:page], @language)
      end
      @page = @page.get_version(params[:rev]) if params[:rev]

      #@edit_wiki_action = wiki_action related_object
      #if session[:content]
      #  @page.attributes = session[:content]
      #  session[:content] = nil
      #  @comment = @page.comment
      #else
      #  @comment = ""
      #end
    end

    def register_tabs_unless_xhr
      register_tabs unless request.xhr?
    end

    def page_url(page = @page)
      { :action => 'page', :id => related_object.id, :page => page.page_name }
    end

    def admin_only
      access_denied unless admin?
    end

    def new_page_object
      Page.new(:language => @language, :page_name => params[:page], :name => params[:page],
                :related_object => related_object)
    end


end
