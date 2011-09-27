class PersonController < ApplicationController
  include OMDB::Controller::ChangesController
  include AjaxController

  cache_sweeper :generic_log_observer

  verify :method => :post, :only => [ :set_abstract, :destroy ]
  verify :xhr => true, :only => [ :set_abstract, :info, :update_facts ]

  before_filter :select_person, :except => [ :new, :create, :orphans ]

  # class extensions (/person/changes)  
  changes_page_for :person

  # instance extensions (e.g. /person/<id>/set_abstract)
  set_abstract_for :person
  edit_aliases_for :person, :language_independent => true
  image_upload_for :person
  history_view_for :person

  before_filter :login_required, :only => [ :destroy_alias, :new_image, :upload_image, :update_facts ]
  before_filter :admin_required, :only => [ :destroy, :destroy_orphans, :merge ]

  caches_page :index, :filmography, :statistics, :history

  # Need to include PageActions after all other filters have been set.
  include PageActions
  
  def statistics
    @object = @person
    render 'common/statistics'
  end

  # Display all people, that are not attached to a movie.
  def orphans
    @people = Person.find_orphans
    @person_pages = Paginator.new self, @people.size, 25, params[:page]
    @people = @people.slice(@person_pages.current.offset, 25)
  end

  def destroy
    @person.destroy
    redirect_to :action => :orphans, :id => nil
  end
  
  def destroy_orphans
    @people = Person.find_orphans
    @people.each do |p| p.destroy end
    redirect_to :action => :orphans, :id => nil      
  end

  def update_facts
    update_attribute :person, :name
    update_attribute :person, :homepage
    update_attribute :person, :birthday
    update_attribute :person, :birthplace
    update_attribute :person, :deathday
    if not @person.save
      render :action => 'edit_facts'
    end
  end
  
  def merge
    unless params[:people].nil?
      @person.merge( params[:people].collect{ |id| Person.find(id) } )
      redirect_to :id => @person.id, :action => :index
    end
  end

  protected

  def related_object; @person end

  def register_tabs
    if @person
      @tabs = [{ :name => 'Overview'.t,
              :url  => { :action => 'index' } } ]

      @tabs << { :name => ADDITIONAL_ARTICLES_TEXT.t,
               :url  => { :action => 'page' } } if @person.has_more_pages?(@language)

      @tabs << { :name => 'Filmography'.t, :url  => { :action => 'filmography' } }
      @tabs << { :name => 'Statistics'.t, :url  => { :action => 'statistics' } }
      @tabs << { :name => "History".t, :url  => { :action => 'history' } }
    else
      @tabs =  [{ :name => "People".t, :url => { :action => 'index' } }]
      @tabs << { :name => 'Orphans'.t + " (#{Person.find_orphans.size})",
              :url  => { :action => 'orphans' } } if admin?
    end
  end

  def select_person
    if params[:id]
      @person = Person.find(params[:id])
      @last_modified = @person.log_entries.first.created_at unless @person.log_entries.empty?
    end
  end
  
end
