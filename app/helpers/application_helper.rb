# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # TODO: Preselect the session lanugage
  def show_available_languages(name)
    select(name, "language", 
             Language.find(:all, :conditions => "active = 1").collect{ 
                |l| [ _('LANGUAGE_' + l.code.upcase), l.id ] })
  end

  # display the translation of flash[:notice|:error] nicely wrapped in a 
  # <p class="notice|error">
  [ :notice, :error ].each do |sym|
    define_method :"flash_#{sym.to_s}" do
      content_tag "p", flash[sym].t, :class => sym.to_s if flash[sym]
    end
  end

  def messages?
    flash[:notice] || flash[:errors] || flash[:error]
  end

  def show_errors
    c = case flash[:errors]
      when String
        flash[:errors].t
      when Array
        flash[:errors].map do |attr, msg| 
          next unless msg
          content_tag("p", attr.to_s.humanize + " " + (msg.is_a?(Array) ? msg.join(".\n") : msg))
        end.join
    end
    return content_tag("div", c, { :class => "error"} ) if c
  end

  def error_messages(object_name)
    object = instance_variable_get("@#{object_name}")
    if object && !object.errors.empty?
        content_tag("ul", object.errors.full_messages.collect { |msg| content_tag("li", msg) })
    else
      ""
    end
  end

  def link_to_new( title, options, html_options = nil )
    content_tag("a", title, :href => url_for(options), :class => 'new-page')
  end

  def link_to_object( object, style = nil )
    title = object.display_title   if object.respond_to?("display_title")
    title = local_title_for object if title.blank?
    base_class_title = (object.base_class_name == "Category") ? object.root.local_name(@language) : 
        (object.base_class_name == "Movie") ? object.class.to_s.t : object.base_class_name.t
    
    link_to_if (object != User.anonymous), title, default_url( object ), :title => "#{base_class_title}: #{title}", :class => style
  end

  def link_localized( object, options, html_options )
    title = local_title_for object
    link_to title, options, html_options
  end

  def local_title_for( object )
    method_name = 'title_for_' + object.class.base_class.to_s.downcase
    if self.respond_to?( method_name.to_sym )
      title = self.send( method_name, object )
      title.nil? ? object.name : title
    elsif object.base_class_name == "Person" or object.base_class_name == "Company" 
      object.name
    elsif object.respond_to?( :local_name )
      title = object.send( :local_name, @language )
      title.nil? ? object.name : title
    else
      object.name
    end
  end

  # Determines, if the current request equals the tab that is going to be
  # displayed. If the remote path_parameters matches the tab_action
  # then the tab will be displayed as active
  # see views/commin/_views.rhtml and register_tabs in application controller
  def action_equal_to_current_request?( action )
    if action.has_key?(:url)
      return true if request.path_parameters['action'] == "edit_page" and action[:url][:action] == "index" and @page.page_name == "index"
      return true if request.path_parameters['action'] == "edit_page" and action[:url][:action] == "page" and @page.page_name != "index"
      return true if request.path_parameters['action'] == "view_diff" and action[:url][:action] == "history"
      action[:url].each_key { |key|
        if action[:url][:action] == 'wiki' and not request.path_parameters['page'].nil?
          return true
        elsif action[:url][key] != request.path_parameters[key.to_s]
          return false
        end
      }
      true
    else
      false
    end
  end

  def default_url(object, page = "index")
 #   if User === object
 #     { :controller => 'user', :id => object.permalink }
 #   else
      url_for object.default_url( page )
#    end
  end

  def render_action(action, object = nil)
    case action[:type]
      when "ajax"
        if not action[:ajax_options][:update].nil?
          action[:ajax_options].merge!( :loading => "Element.show('#{action[:ajax_options][:update]}')" )
        end
        if action[:image].nil?
          link_to_remote action[:name], action[:ajax_options]
        else
          link_to_remote image_tag(action[:image]), action[:ajax_options], :title => action[:name], :alt => action[:name]
        end
      when "form"
        form_tag action[:url], (action[:html_options] ||= {})
      when "form-remote"
        form_remote_tag action
      when "titled"
        link_to object.name, action[:url]
      when "titled-ajax"
        if not object.nil?
          action[:ajax_options][:url].merge!(:id => object.id)
        end
        link_to_remote object.name, action[:ajax_options]
      else
        link_to action[:name], action[:url], action[:html_options]
    end
  end
  
  def action_name( action )
    action[:name].gsub(' ', '_').underscore.downcase
  end
  
  def fetch_actions(object)
    if object.frozen?
      fetch_frozen_actions object
    else
      fetch_unfrozen_actions object
    end
  end
  
  def fetch_controller(object)
    controller = object.class.base_class.to_s.capitalize + "Controller"
    return Module.const_get(controller)
  end
  
  def merge_ajax_ids(action, options = {})
    action[:ajax_options][:url].merge!(options)
    action
  end

  def base_language_only
    yield if Locale.base?
  end

  def not_base_language
    yield unless Locale.base?
  end

  def language_dropdown
    html = ''
    LOCALES.keys.each { |locale|
      l = Language.find_by_iso_639_1(locale)
      next if l.id == @language.id
      url = { :controller => 'session', :action => 'set_language', :language => l.id }
      html += link_to_remote(l.to_s.t, { :url => url }, { :href => url_for(url) })
    }
    html
  end

  def active_languages_hash
    languages = {}
    LOCALES.keys.each { |locale|
      l = Language.find_by_iso_639_1(locale)
      languages[l.english_name.t] = l.id
    }
    # independent language
    i = Language.find(1)
    languages[i.english_name.t] = i.id if @allow_independent
    languages
  end

  def stripped_base_class( object )
    object.class.base_class.to_s.split("::").last.downcase
  end

  # build a form using the LabelledFormBuilder (see lib/omdb/forms.rb)
  def labelled_form_for(name, object, options={}, &proc)
    form_for(name, object, options.merge(:builder => LabelledFormBuilder), &proc)
  end

  def labelled_remote_form_for(name, object, options={}, &proc)
    remote_form_for(name, object, options.merge(:builder => LabelledFormBuilder), &proc)
  end

  # renders a self-disabling submit button
  def oneshot_submit_tag(value, options = {})
    disabled_text = (options.delete(:disable_with) || value).t
    submit_tag value.t,
               options.reverse_merge(:onclick => "this.setAttribute('oldvalue', this.value); this.value='#{disabled_text}'; this.disabled=true; return true;")
  end

  def error_messages_on_field(object, field)
    if object && errors = object.errors.on(field.to_s)
      ' <em>' << errors.select { |e| !e.empty? }.join('</em><em>') << '</em>'
    end
  end

  def link_to_user(user)
    name = h(user.nil? ? 'unknown' : user.display_title)
    return name if user.nil? || user.anonymous?
    user.save if user.permalink.blank?
    link_to name, :controller => 'user', :id => user.permalink
  end

  def movie_method( object )
    case object
      when Person
        :filmography
      else
        :movies
    end
  end

  def render_tree_for( object )
    content_tag( 'ul', object.children.collect{ |child|
        tree = (child.children.empty? ? "" : render_tree_for( child ))
	text = " (de: #{child.local_name( Language.find_by_iso_639_1('de') )}, en: #{child.name})"
	text << (child.abstract(@language).new_record? ? " <strong>kein abstract</strong>" : "")
        content_tag( 'li', link_to_object(child) + text + tree )
    })
  end


  def windowed_pagination_links(pagingEnum, options)
     link_to_current_page = options[:link_to_current_page]
     always_show_anchors = options[:always_show_anchors]
     padding = options[:window_size]

     current_page = pagingEnum.page
     html = ''

     padding = padding < 0 ? 0 : padding
     first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
     last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

     html << yield(1) if always_show_anchors and not first == 1

     first.upto(last) do |page|
       (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
     end

     html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
     html
   end
end
