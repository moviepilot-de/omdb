module LogEntryHelper
  def display_log_entry( entry )
    begin
      html = content_tag( :tr, 
        content_tag( :td, user_of_log_entry( entry ) ) +
        date_entry_td( entry ) +
        content_tag( :td, log_entry_text( entry ) ) )
      @last_log_entry = entry
      return html
    rescue
      # :BUG: This will filter out all log-entries, that are invalid (because
      # of deleted objects, or something like that), but this should be handled
      # in some other way.. but this will work for the time beeing .. 
      return ""
    end
  end
  
  def display_contrib_log_entry( entry )
    begin
      return "" if entry.related_object.nil?
      html = content_tag( :tr,
        date_entry_td( entry ) +
        content_tag( :td, link_to_object( entry.related_object ) ) +
        content_tag( :td, log_entry_text( entry ) ) )
      return html
    rescue
      return ""
    end
  end
  
  def display_log_entry_for_changes_page( entry )
    begin
      return "" if entry.related_object.nil?
      html = content_tag( :tr,
        content_tag( :td, user_of_log_entry(entry)) +
        date_entry_td( entry ) +
        content_tag( :td, link_to_object( entry.related_object ) ) +
        content_tag( :td, log_entry_text( entry ) ) )
        @last_log_entry = entry
      return html
    rescue
      return ""
    end
  end
  
  def user_of_log_entry( entry )
    if @last_log_entry.nil? or @last_log_entry.user != entry.user or @last_log_entry.ip_address != entry.ip_address
      if entry.user == User.anonymous
        return entry.ip_address
      elsif entry.user.nil?
        return "unknown".t
      else
        return link_to_object( entry.user ) + " (" + link_to( "contribs".t, :controller => 'user', :id => entry.user.permalink, :action => :contribs ) + ")"
      end
    else
      return ""
    end
  end
  
  def date_entry_td( entry )
    if @last_log_entry.nil? or @last_log_entry.created_at.strftime("%Y-%m-%d %H:%M") != entry.created_at.strftime("%Y-%m-%d %H:%M")
      content_tag( :td, entry.created_at.strftime("%Y-%m-%d&nbsp;%H:%M") )
    else 
      tag( :td )
    end
  end
  
  def log_entry_text( entry )
    method = "log_entry_for_" + entry.class.to_s.underscore
    value = self.send(method, entry)
    if entry.removal? || entry.deletion?
      "<del>#{value}</del>"
    else
      value
    end
  end

  def log_entry_for_content_log_entry(entry)
    result = ''
    result << (entry.creation? ? 'created' : 'changed') << ' '
    result << 'article' if Page === entry.content
    result << 'abstract' if Abstract === entry.content
    result = result.translate.dup # dup ist wichtig da wir sonst später die Übersetzung ändern
    result << ' '
    result << link_to_object(entry.content) if Page === entry.content
    result << ' (' << link_to( "view diff".t, :controller => entry.content.related_object.default_url[:controller],
                                              :action => 'view_diff', 
                                              :id => entry.related_object.id,
                                              :page => entry.content.page_name, 
                                              :from => entry.old_value, 
                                              :to => entry.new_value ) << ')' if Page === entry.content and not entry.creation?
    result << content_tag(:div, ((entry.comment.nil? or entry.comment.empty?) ? "no comment entered".t : entry.comment), :class => :comment)
    result
  end
  
  def log_entry_for_log_entry( entry )
    if entry.creation? and not entry.attribute == "assignable" and not entry.attribute == 'runtime' and not entry.attribute == 'end'
      if entry.attribute == "self"
        "created <em>%s</em>" / entry.related_object.name
      elsif entry.attribute == "name_alias"
        "alias <em>%s</em>" / entry.new_value
      end
    elsif entry.attribute == 'end'
      "release date set to %s" / entry.new_value.to_s
    elsif entry.attribute == "name_alias"
      "alias <em>%s</em>" / entry.old_value
    else
      sprintf( "changed <strong>%s</strong> from %s to %s".t, entry.attribute.t, entry.old_value.to_s, entry.new_value.to_s )
    end
  end
  
  def log_entry_for_assoc_log_entry( entry )
    object = entry.load_object
    if object.nil?
      "<em>" + "deleted #{entry.attribute.downcase}".t + "</em>"
    elsif entry.old_value.nil?
      sprintf( "#{entry.attribute.split('/').last} %s".t, (object.class.to_s.demodulize == "Language") ? object.english_name.t : link_to_object( object ) )
    else
      sprintf( "#{entry.attribute.split('/').last} %s".t, (object.class.to_s.demodulize == "Language") ? object.english_name.t : link_to_object( object ) )
    end
  end
  
  def log_entry_for_cast_log_entry( entry )
    if entry.old_value.nil?
      values = entry.new_value.split(",")
      sprintf( "%s as %s".t, link_to_object( Person.find( values.first ) ), link_to_object( Job.find( values.last ) ) )
    else
      values = entry.old_value.split(",")
      sprintf( "%s as %s".t, link_to_object( Person.find( values.first ) ), link_to_object( Job.find( values.last ) ) )
    end
  end
end
