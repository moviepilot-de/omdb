class CharacterController < ApplicationController
  include AjaxController

  cache_sweeper :generic_log_observer
  
  verify :method => :post, :only => [ :set_abstract ]
  verify :method => :get, :only => [ :index, :portrayed ]
  verify :xhr => true, :only => [ :set_abstract ]

  before_filter :select_character, :except => [ :new, :create, :list ]

  # Public Methods (aka actions)
  set_abstract_for :character
  edit_aliases_for :character, :allow_independent => true
  image_upload_for :character
  history_view_for :character
  movie_list_for   :character
  
  before_filter :login_required, :only => [ :new_image, :destroy_alias, :upload_image, :new, :create, :new_cast, :update_facts ]

  include PageActions

  def new
    case params[:view]
      when 'wiki'
        edit_page
      else
        @cast = Cast.find(params[:cast])
        @other_characters = Character.find_all_by_name( @cast.comment )
        @character = Character.new
        @character.name = @cast.comment
        @new_character_submit_action = new_character_submit_action
        @character_assign_cast_action = character_assign_cast_action
    end
  end

  def create
    @cast = Cast.find(params[:cast])
    @movie = @cast.movie
    @character = Character.new(params[:character])
    @character.save
    @cast.character = @character
    @cast.save
    @close_box = true
    render :action => '../cast/update_cast'
  end

  def portrayed
    @people = {}
    @character.casts.each do |c|
      @people[c.person] = [] if @people[c.person].nil?
      @people[c.person].push(c.movie)
    end
  end
  
  def new_cast
    @assign_cast_action = character_assign_cast_ajax_action
  end
  
  def update_facts
    update_attribute :character, :name
    if not @character.save
      render :action => 'edit_facts'
    end
  end
  
  private

  def related_object; @character end
  
  def title
    "Character"
  end
  
  def select_character
    @character = Character.find(params[:id])
    add_popularity @character
  end

  def character_assign_cast_ajax_action
    { :type => "titled-ajax", :ajax_options => { :url => { :controller => "cast", :action => "assign_character" } } }
  end

  def new_character_submit_action
    { :type => "form", :url => { :action => "create", :cast => @cast.id } }
  end

  def character_assign_cast_action
    { :type => "form-remote", :url => { :controller => "cast", :action => "assign_character", :id => @cast.id } }
  end
  
  def register_tabs
    return unless @character
    @tabs = [
      { :name => 'Overview'.t, :url  => { :action => 'index' } },
      { :name => 'Movies'.t, :url  => { :action => 'movies' } }
    ]
    @tabs << { :name => ADDITIONAL_ARTICLES_TEXT.t,
               :url  => { :action => 'page' } } if @character.has_more_pages?(@language)

    @tabs << { :name => 'Portrayed by'.t, :url  => { :action => 'portrayed'} }
    @tabs << { :name => 'History'.t, :url  => { :action => 'history' } }
  end
  
end
