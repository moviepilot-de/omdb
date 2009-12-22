class YearController < ApplicationController
  before_filter :register_tabs

  public

  def index
    @results = Movie.search_by_year( params[:id], ( params[:page] || 1 ) )
    respond_to do |type|
      type.html { render 'common/movies' }
      type.js { render :template => 'common/update_search_listing', :layout => false }
    end
  end

  private
  
  def register_tabs
    @tabs = [{ :name => "Movies".t,
               :url => { :action => 'index' } }]
  end
end
