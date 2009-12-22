class CategoryController < ApplicationController
  include OMDB::Controller::ChangesController
  include AjaxController

  cache_sweeper :generic_log_observer

  verify :method => :get, :only => [ :index, :movies, :statistics, :edit ]
  verify :method => :post, :only => [ :edit_facts, :add_user_vote, :update_facts, :set_abstract, :destroy, :create ]

  verify :xhr => true, :only => [ :add_user_vote, :edit_facts, :update_facts, :set_abstract, :all_genres, :all_epoches, :all_terms, :new, :create ]

  # class extensions (/category/changelog)  
  changes_page_for :category

  # instance extensions (e.g. /category/<id>/set_abstract)
  set_abstract_for :category
  edit_aliases_for :category
  image_upload_for :category
  history_view_for :category
  movie_list_for   :category

  before_filter :select_category, :except => [ :all_genres, :all_terms, :all_epoches, :create ]
  before_filter :select_category_alias, :except => [ :add_user_vote, :all_genres, :all_terms, :all_epoches, :new, :create ]
  before_filter :login_required, :only => [ :destroy_alias, :new_image, :upload_image ]
  before_filter :admin_required, :only => [ :new, :destroy, :create, :merge ]

  caches_page :index, :movies, :statistics

  include PageActions

  # Public Methods (aka actions)

  def new
    @category = Category.new( :parent => @category );
    @alias = @base_alias = NameAlias.new
  end
  
  def create
    @category = Category.new( params[:category] )
    set_local_name unless params[:alias].nil? or params[:alias][:name].nil?
    set_base_name unless params[:base_alias].nil? or params[:base_alias][:name].nil?
    set_parent unless params[:parent].nil?
    @category.save
    render(:update) do |page|
      page.visual_effect :fade, 'lightbox'
      page.redirect_to :id => @category.id, :action => :index
    end
  end
  
  def tree
    @object = @category
    render 'common/tree'
  end

  def statistics
    @object = @category
    render 'common/statistics'
  end
  
  def merge
    if not params[:categories].nil?
      categories = params[:categories].collect {|c| Category.find(c.to_i)}
      @category.merge( categories )
      redirect_to :id => @category.id, :action => :index
    end
  end
  
  def destroy
    @category.destroy
    redirect_to :id => @category.parent.id
  end

  def edit_facts
    @alias = @category.aliases.local(@language).first
    @base_alias = @category.aliases.local( Locale.base_language ).first || NameAlias.new( :name => "" )
    if @alias.nil?
      @alias = NameAlias.new( :related_object => @category, :name => @base_alias.name, :language => @language )
      @alias.save
    end
  end
  
  def update_facts
    set_local_name unless params[:alias].nil? or params[:alias][:name].nil?
    set_base_name unless params[:base_alias].nil? or params[:base_alias][:name].nil?
    set_parent unless params[:parent].nil?
    set_assignable if admin?
    set_slug if admin? and params[:category] and params[:category][:slug] != @category.slug
  end
  
  def all_genres
    @movie = Movie.find( params[:movie] )
    render :partial => 'search/category', :collection => Category.genre.all_ordered_children, :locals => { :type => 'genre', :name => 'genre' }
  end

  def all_terms
    @movie = Movie.find( params[:movie] )
    render :partial => 'search/category', :collection => Category.term.all_ordered_children, :locals => { :type => 'term', :name => 'term' }
  end
  
  def all_epoches
    @movie = Movie.find( params[:movie] )
    render :partial => 'search/category', :collection => Category.epoch.all_ordered_children, :locals => { :type => 'epoch', :name => 'epoch' }
  end  
  
  def sort_name_aliases
    param  = "name_aliases-category-" + @category.id.to_s
    if not params[param].nil?
      params[param].each do |p|
        name_alias = NameAlias.find(p.split(/_/).last)
        name_alias.position = params[param].index(p) + 1
        name_alias.save
      end
    end
    render :nothing => true
  end
  
  private

  def set_local_name
    a = @category.aliases.local( @language ).first || NameAlias.new( :related_object => @category, :language => @language )
    a.name = params[:alias][:name]
    a.save
  end

  def set_base_name
    a = @category.aliases.local( Locale.base_language ).first || NameAlias.new( :related_object => @category, :language => Locale.base_language )
    a.name = params[:base_alias][:name]
    a.save
  end

  def set_parent
    return if params[:parent].nil?
    set_parent_for @category, params[:parent]
  end
  
  def set_assignable
    @category.assignable = params[:category][:assignable]
    @category.save
  end

  def set_slug
    @category.slug = params[:category][:slug]
    @category.save
  end

  def register_tabs
    @tabs = [
      { :name => "Overview".t, :url  => { :action => 'index' } },
      { :name => "Movies".t, :url => { :action => "movies"} },
      { :name => "Statistics".t, :url => { :action => "statistics"} },
      { :name => "History".t, :url => { :action => "history"} }
    ]
    @tabs << { :name => "Additional Pages".t,
               :url  => { :action => 'page' } } if @category.has_more_pages?(@language)
  end

  def related_object; @category end

  def select_category
    @category = Category.find params[:id]
    @last_modified = @category.log_entries.first.created_at unless @category.log_entries.empty?
  end
  
  def select_category_alias
    local_alias = @category.name_aliases.local(@language)
    if local_alias.nil? or local_alias.empty?
      local_alias = @category.name_aliases.local(Language.find_by_iso_639_1("en"))
    end
    @category_alias = local_alias.first
    @category_alias
  end
  
end
