class CountryController < ApplicationController
  include AjaxController

  cache_sweeper :generic_log_observer

  verify :method => :post, :only => [ :set_abstract ]
  verify :xhr => true, :only => [ :set_abstract, :edit_facts ]

  before_filter :select_country

  set_abstract_for :country
  edit_aliases_for :country
  image_upload_for :country
  history_view_for :country
  movie_list_for   :country

  before_filter :login_required, :only => [ :destroy_alias, :new_image, :upload_image ]

  include PageActions


  def statistics
    @object = @country
    logger.debug "countrie's oldest movie: #{@country.chronological_movies.first.inspect}"
    render 'common/statistics'
  end

  def info
    @movie = Movie.find(params[:movie]) unless params[:movie].nil?
  end

  def edit_facts
    @alias = @country.aliases.local(@language).first
    @base_alias = @country.aliases.local( Locale.base_language ).first
    if @base_alias.nil?
      @base_alias = NameAlias.new( :related_object => @country, :name => @country.english_name, :language => Locale.base_language )
      @base_alias.save
    end
    if @alias.nil?
      @alias = NameAlias.new( :related_object => @country, :name => @base_alias.name, :language => @language )
      @alias.save
    end
  end

  def update_facts
    set_local_name
    set_base_name
  end


  private

  def related_object; @country end

  def register_tabs
    return unless @country
    @tabs = [ { :name => "Overview".t, :url  => { :action => "index" } },
              { :name => "Movies".t, :url  => { :action => "movies" } },
              { :name => "Statistics".t, :url  => { :action => "statistics" } } 
    ]
    @tabs << { :name => ADDITIONAL_ARTICLES_TEXT.t,
               :url  => { :action => 'page' } } if @country.has_more_pages?(@language)
  end


  def set_local_name
    a = @country.aliases.local( @language ).first
    a.name = params[:alias][:name]
    a.save
  end

  def set_base_name
    if admin? and not params[:base_alias][:name].nil?
      a = @country.aliases.local( Locale.base_language ).first
      a.name = params[:base_alias][:name]
      a.save
    end
  end

  def select_country
    @country = Country.find(params[:id])
    @last_modified = @country.log_entries.first.created_at unless @country.log_entries.empty?
  end

  def title( lang = Locale.base_language )
    @country.nil? ? "" : " - #{@country.local_name( lang )}"
  end
  
end
