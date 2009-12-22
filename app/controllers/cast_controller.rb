# CastController
#
# Handles all cast related actions. This controller will just accept ajax calls.
#
# Author:: Benjamin Krause <bk@benjaminkrause.com>

class CastController < ApplicationController
  include AjaxController
  
  cache_sweeper :cast_log_observer
  cache_sweeper :generic_log_observer

  verify :method => :post, :only => [ :update, :update_character ]

  verify :xhr => true, :only => [ :new, :new_cast, :edit, :freeze_attribute, :unfreeze_attribute ]

  before_filter :select_cast, :except => [ :new, :new_cast, :create, :create_cast, :edit, :update ]
  before_filter :select_movie, :only => [ :new, :new_cast, :create, :create_cast, :edit, :update ]

  before_filter :editor_required, :only => [ :freeze_attribute, :unfreeze_attribute ]

  helper :character

  def new 
    @cast = Cast.new 
    render :action => 'new', :layout => false 
  end 

  def new_cast 
    @cast = Actor.new 
    render :action => 'new_cast', :layout => false 
  end

  # Create a new crew
  def create
    if select_or_create_job and select_or_create_person( :crew )
      @cast.movie = @movie
      @cast.save
      update_movie_cast_list @cast.job.department, :crew
    else
      render :inline => "Error".t, :status => 409
    end
  rescue ActiveRecord::RecordNotFound
    render :inline => "Already destroyed".t, :status => 404
  end
  
  # Create a new Cast (a crew member who is an actor, that is)
  def create_cast
    begin
      @cast = Actor.new( :job => Actor.default_job )
      @cast.movie = @movie
      @cast.comment = params[:cast][:comment]
      if select_or_create_person( :cast )
        @cast.save
        update_movie_cast_list @cast.job.department, :cast
      else
        render :inline => "Error".t, :status => 409
      end
    rescue ActiveRecord::RecordNotFound
      render :inline => "Already destroyed".t, :status => 404
    end
  end
  
  # Edit a whole department
  def edit
    @department = Department.find(params[:department])
  end

  def assign_character
    assign_character_to_cast
    render :partial => 'update_cast', :locals => { :close_box => true }
  end

  def create_new_character
    character = Character.new( :name => @cast.comment )
    @cast.character = character
    @cast.save
    render :partial => 'update_cast', :locals => { :close_box => true }
  end

  def remove_character
    @cast.character = nil
    @cast.save
    render :partial => 'update_cast', :locals => { :close_box => false }
  end

  # Update a whole department
  def update
    @department = Department.find(params[:department])
    klass = (@department == Department.acting) ? Actor : Cast
    remove_unwanted_casts
    create_new_casts klass
    create_new_people klass

    @movie.reload
    
    update_movie_cast_list @department
  end

  def update_character
    if !@cast.attribute_frozen?(:self) && params[:cast]
      @cast.comment = params[:cast][:comment] unless params[:cast][:comment].nil?
      @cast.lead    = params[:cast][:lead] unless params[:cast][:lead].nil?
      @cast.save
    end
    set_cast_alias if params[:alias]
    render :partial => 'update_cast', :locals => { :close_box => true }
  end

  # Finalize a movie-person-job relation, this cast is no longer editable.  
  # See Freezable mixin
  #
  # intentionally overwrites AjaxController#freeze_attribute
  def freeze_attribute
    @cast.freeze_attribute :self
    @cast.save
    render :partial => 'update_cast'
  end

  # Make a movie-person-job relation editable again. See Freezable mixin
  #
  # intentionally overwrites AjaxController#freeze_attribute
  def unfreeze_attribute
    @cast.unfreeze_attribute :self
    @cast.save
    render :partial => 'update_cast'
  end

  def edit_alias
    @alias = @cast.aliases.local( @language ).first
  end

  def set_alias
    if @cast.class == Actor
      set_cast_alias
    else
      raise "Cast Alias only for Actors"
    end
    render :partial => 'update_cast', :locals => { :close_box => true }
  end

  def set_job
    old_department = @cast.job.department
    new_job = Job.find( params[:edit_cast_job] )
    new_klass = (new_job.department == Department.acting) ? Actor : Cast
    @cast.type = new_klass.to_s
    @cast.job = new_job
    @cast.comment = params[:cast][:comment]
    @cast.save
    @movie.reload
    render :update do |page|
      page.replace_html "movie-list-#{@cast.job.department.id}", :partial => 'movie/cast', :locals => { :department => @cast.job.department, :show_edit_links => true }
      page.replace_html "movie-list-#{old_department.id}", :partial => 'movie/cast', :locals => { :department => old_department, :show_edit_links => true }
    end
  end

  def create_character
    @characters = Searcher.search_characters(@cast.comment, @language.code) unless @cast.comment.empty?
    render :action => 'create_character', :layout => false
  end

  private
  
  def update_movie_cast_list( department, form_name = nil )
    render :update do |page|
      page.replace_html "movie-list-#{department.id}", :partial => 'movie/cast', :locals => { :department => department, :show_edit_links => true }
      if [ Department.directing, Department.writing, Department.camera, Department.writing, 
           Department.production, Department.editing ].include?( department )
        page.replace_html "overview-crew", :partial => 'movie/overview_crew'
      end
      page.call "clear#{form_name.to_s.humanize}Form" unless form_name.nil?
    end
  end
  
  def select_cast
    @cast   = Cast.find(params[:id])
    @movie  = @cast.movie
    @person = @cast.person
  end

  def select_movie
    @movie  = Movie.find(params[:movie])
  end

  def select_person
    @person = Person.find(params[:person])
  end


  def assign_character_to_cast
    @character = Character.find(params[:character])
    @cast.character = @character
    @cast.save
  end

  def remove_unwanted_casts
    Cast.employees( @movie, @department ).each {|c|
      next if c.frozen? or c.movie_id != @movie.id
      if params[:casts].nil? or not params[:casts].include?(c.id.to_s)
        c.destroy
      end
    }
  end

  def create_new_casts( klass )
    job = @department.default_job
    params[:people].each { |id|
      p = Person.find(id) rescue nil
      next unless 
      cast = klass.new.init(p, @movie, job)
      cast.save
    } unless params[:people].nil?
  end

  def create_new_people( klass )
    job = @department.default_job
    params[:new_people].each { |name|
      p = Person.new :name => name
      cast = klass.new.init(p, @movie, job)
      cast.save
    } unless params[:new_people].nil?
  end

  def select_or_create_job
    if not params[:crew][:job].nil? and not params[:crew][:job].empty?
      @job = Job.find( params[:crew][:job] )
    elsif editor?
        @job = Job.new
        @job.parent = Department.crew
        @job.aliases << NameAlias.new( :name => params[:crew][:new_job].strip, 
                                     :language => Locale.base_language )
        @job.aliases << NameAlias.new( :name => params[:crew][:new_job].strip, 
                                     :language => @language ) unless @language == Locale.base_language
    else
      @job = Job.default_job
    end
    @cast = (@job.department == Department.acting) ? Actor.new : Cast.new
    @cast.job = @job
  end

  def select_or_create_person( param_name )
    if not params[param_name][:new_person].nil? and not params[param_name][:new_person].empty?
      @cast.person = Person.new( :name => params[param_name][:new_person] )
    else
      @cast.person = Person.find( params[param_name][:person] )
    end
  end
 
  def set_cast_alias
    if not @cast.aliases.local( @language ).empty?
      @alias = @cast.aliases.local( @language ).first
      @alias.name = params[:alias][:name]
    else
      @alias = NameAlias.new( :name => params[:alias][:name], 
                              :language => @language, 
                              :related_object => @cast )
    end
    if params[:alias][:name].empty?
      @alias.destroy
    else
      @alias.save
    end
  end

end
