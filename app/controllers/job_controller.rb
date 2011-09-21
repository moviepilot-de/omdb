class JobController < ApplicationController
  include AjaxController

  cache_sweeper :generic_log_observer
  
  before_filter :select_job
  before_filter :admin_required, :only => :destroy

  set_abstract_for :job
  edit_aliases_for :job
  image_upload_for :job
  history_view_for :job

  helper :movie
  helper :javascript
  
  caches_page :index, :people

  before_filter :login_required, :only => [ :destroy_alias, :new, :create, :merge_jobs, :edit_facts, :update_facts ]

  include PageActions

  def people
    @casts = @job.casts
  end

  def new
    @alias = NameAlias.new
    @base_alias = NameAlias.new
  end

  def create
    @new_job = Job.new
    @new_job.parent = @job
    @new_job.aliases << NameAlias.new( :name => params[:alias][:name], :language => @language )
    @new_job.aliases << NameAlias.new( :name => params[:base_alias][:name], 
           :language => Locale.base_language ) unless @language == Locale.base_language
    @new_job.save
    render :update do |page|
      page.replace_html 'overview-subcategories', :partial => 'overview_children'
    end
  end

  def tree
    @object = @job
    render 'common/tree'
  end
  
  def merge_jobs
    if not params[:jobs].nil? and not params[:jobs].include?(@job.id.to_s)
      jobs = params[:jobs].collect {|c| Job.find(c.to_i)}
      Job.merge_jobs(@job, jobs)
      render :update do |page|
        page.replace_html "overview-aliases", :partial => 'overview_aliases'
	      page.replace_html "headline", :partial => 'headline'
      end
    end
  end
  
  def destroy
    @job.destroy
    redirect_to default_url(@job.parent)
  end

  def edit_facts
    @alias = @job.aliases.local(@language).first
    @base_alias = @job.aliases.local( Locale.base_language ).first
    if @alias.nil?
      @alias = NameAlias.new( :related_object => @job, :name => @base_alias.name, :language => @language )
      @alias.save
    end
  end

  def update_facts
    set_local_name
    set_base_name
    set_parent if editor?
  end

  private

  def set_local_name
    a = @job.aliases.local( @language ).first
    a.name = params[:alias][:name]
    a.save
  end

  def set_base_name
    return if params[:base_alias].nil?
    a = @job.aliases.local( Locale.base_language ).first
    a.name = params[:base_alias][:name]
    a.save
  end

  def set_parent
    return if params[:parent].nil?
    parent = Job.find( params[:parent] )
    @job.parent = parent
    @job.save!
  end

  def title( lang = Locale.base_language )
    ""
  end

  def register_tabs
    @tabs = [
      { :name => "Overview".t, :url  => { :action => 'index' } },
      { :name => "Selected People".t, :url  => { :action => 'people' } },
      { :name => "History".t, :url  => { :action => 'history' } }
    ]
  end

  def select_job
    @job = Job.find params[:id]
    @last_modified = @job.log_entries.first.created_at unless @job.log_entries.empty?
  end

  def related_object; @job end

end
