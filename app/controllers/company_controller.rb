class CompanyController < ApplicationController
  include AjaxController

  cache_sweeper :generic_log_observer

  verify :method => :get, :only => [ :index, :movies, :statistics, 
                                     :edit, :ruins ]
  verify :method => :post, :only => [ :edit_facts, :add_user_vote, :update_facts, 
                                      :create_cover, :set_abstract, :destroy ]

  verify :xhr => true, :only => [ :edit_facts, :edit_aliases, :set_abstract ]

  before_filter :select_company, :except => :ruins
  before_filter :admin_required, :only => :destroy

  set_abstract_for :company
  edit_aliases_for :company, :language_independent => true
  image_upload_for :company
  history_view_for :company
  movie_list_for   :company  
  
  before_filter :login_required, :only => :destroy_alias
  before_filter :login_required, :only => [ :new_image, :upload_image, :update_facts, :edit_aliases, :set_parents ]

  helper :movie
  
  caches_page :index, :movies, :statistics

  include PageActions

  def top_movies
    @movies = @company.highest_rated_movies
    render 'common/top_movies'
  end

  def blockbuster
    @movies = @company.blockbuster
    render 'common/blockbuster'
  end

  def ruins
    @companies = Company.find_orphans
    @company_pages = Paginator.new self, @companies.size, 25, params[:page]
    @companies = @companies.slice(@company_pages.current.offset, 25)
  end

  def statistics
    @object = @company
    render 'common/statistics'
  end

  def destroy
    @company.destroy
    redirect_to :action => :ruins, :id => nil
  end

  def update_facts
    update_attribute :company, :name
    set_parent
    @company.save
  end

  def edit_aliases
    @aliases = @company.aliases
    @language_independent = true
    render 'common/edit_aliases'
  end

  def set_parent
    return if params[:parent].nil?
    if params[:parent].empty?
      @company.parent = nil
    else
      set_parent_for @company, params[:parent]
    end
  end

  private

  def related_object; @company end

  def select_company
    if params[:id]
      @company = Company.find(params[:id])
      @last_modified = @company.log_entries.first.created_at unless @company.log_entries.empty?
    end
  end

  def register_tabs
    return unless @company
    @tabs = [
      { :name => "Overview".t, :url  => { :action => "index" } },
      { :name => "Movies".t,   :url  => { :action => "movies"} },
      { :name => "History".t,   :url  => { :action => "history"} }]
    if @company.movies.size > 1
      @tabs.push( { :name => "Statistics".t,
                    :url  => { :action => "statistics"} } )
    end
    @tabs << { :name => ADDITIONAL_ARTICLES_TEXT.t,
               :url  => { :action => 'page' } } if @company.has_more_pages?(@language)
  end

end
