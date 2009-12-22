class NameAliasController < ApplicationController
  include AjaxController
  
  verify :params => :id
  
  before_filter :select_alias
  before_filter :admin_required
  
  # this controller is just for freezing/unfreezing name_aliases
  # (imported via AjaxController)

  private 
  
  def select_alias( id = params[:id] )
    @name_alias = NameAlias.find( id )
  end
end
