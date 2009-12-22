class ContentLogObserver < ActionController::Caching::Sweeper
  observe Content
  
  def after_create( page )
    write_log page
  end
  
  def after_update( page )
    write_log page
  end

  private
  def write_log(page)
    # :TODO: fix me and allow content-logging for user-pages
    return if page.related_object.class == User

    page.write_log controller.send( :current_user ) unless controller.nil? 
  end
end
