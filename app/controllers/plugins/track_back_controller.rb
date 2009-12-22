module TrackBackController
  
  def self.included(base) # :nodoc:
    base.extend TrackBackController
  end
  
  def trackback
    if request.get?
      @object = get_trackback_object
      render :template => 'common/trackbacks', :layout => false
    elsif request.post?
      verify_akismet_key
      params[:title] = params[:url] if params[:title].nil?
      @trackback = get_trackback_object.track_backs.create( :url       => params[:url], 
                                                            :title     => params[:title], 
                                                            :excerpt   => params[:excerpt], 
                                                            :blog_name => params[:blog_name], 
                                                            :language  => Language.pick( params[:language] || 'en' ),
                                                            :is_spam   => check_spam )
      render :template => 'common/trackback_status', :layout => false
    else
      render :text => 'Method Not Allowed', :status => 405
    end
  end
  
  def check_spam
    is_spam?(
      :comment_content    => (params[:excerpt] || params[:title]),
      :comment_type       => "trackback",
      :comment_author_url => params[:url] )
  end

  def get_trackback_object
    instance_variable_get("@#{self.controller_name}")
  end
end
