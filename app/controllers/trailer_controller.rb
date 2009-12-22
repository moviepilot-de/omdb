class TrailerController < ApplicationController
  include AjaxController
  
  before_filter :select_trailer, :except => [ :edit_movie_trailers, :update_movie_trailers ]
  before_filter :select_movie, :only => [ :edit_movie_trailers, :update_movie_trailers ]
  
  layout 'ajax_box'
    
  before_filter :admin_required, :only => [ :upload, :destroy ]
    
  def index
    render :action => :index, :layout => false
  end
  
  def update_movie_trailers
    if update_movie_trailer('trailer', false, @language) and update_movie_trailer('english_trailer', true)
      render :update do |page|
        page.call('box.deactivate')
        page.replace_html 'overview-trailers', :partial => 'movie/overview_trailers', :locals => { :language => @language }
        page.replace_html 'overview-trailers-en', :partial => 'movie/overview_trailers', 
                          :locals => { :language => Locale.base_language } unless @language.code == Locale.base_language.code
        page.show 'overview-trailers-en-headline'
        page.show 'overview-trailers-en'
      end
    else
      render :action => :edit_movie_trailers
    end
  end
  
  def destroy
    @trailer.destroy
    render :update do |page|
      page.remove "edit-trailer-#{@trailer.id.to_s}"
    end
  end
  
  private

  def update_movie_trailer( name, optional = false, language = Locale.base_language )
    item = instance_variable_get("@#{name}")
    return true if item.nil? or item.attribute_frozen?(:key)
    if params[name].nil? or params[name][:key].empty? 
      item.destroy
      return true
    end
    
    item.update_attributes( params[name] )
    item.source = 'youtube'
    item.movie = @movie
    item.language = language
    
    return item.save
  end
  
  def select_trailer
    @trailer = Trailer.find params[:id]
    @movie = @trailer.movie
  end
  
  def select_movie
    @movie = Movie.find(params[:movie])
    @trailer = @movie.trailer( @language )
    @english_trailer = @movie.trailer( Locale.base_language ) unless @language.code == Locale.base_language.code
  end
end
