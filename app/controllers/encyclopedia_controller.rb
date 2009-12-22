class EncyclopediaController < ApplicationController
  helper :movie
  before_filter :register_tabs  
  
  def index
  end
  
  private

  def register_tabs
    @tabs = [{ :name => "Encyclopedia".t, :url => { :action => 'index' } }]
  end
  
end
