module AjaxHelper

  def button_to_remote(name, options, html_options = nil)
    opts = (html_options ||= {}).merge( :onclick => remote_function(options) + "; return false;")
    content_tag("button", name, opts )
  end
  
  def submit_button_to_remote(name, options = {})
    options[:with] ||= 'Form.serialize(this.form)'
    options[:html] ||= {}
    options[:html][:type] = 'submit'
    options[:html][:name] = name
    options[:html][:onclick] = "#{remote_function(options)}; return false;"
    content_tag("button", name, options[:html])
  end

  def lightbox(url, options = {})
    options[:draggable] ||= false
    options[:overlay] = true if options[:overlay].nil?
    "try { box = new lightbox('" + url_for( url ) + "', " + options[:draggable].to_s + ", " + options[:overlay].to_s + ") } catch (e) {}"
  end

  def lightbox_edit_link( link_text, method )
    link_to_function link_text, lightbox( :action => "set_#{method.to_s}" ), :class => 'edit'
  end
  
  def lightbox_form_tag( url, opts = {} )
    options = {
      :url     => url,
      :loading => "Element.show('ajax-activity-indicator'); $('add_button').disabled = true;",
      :loaded  => "Element.hide('ajax-activity-indicator'); $('add_button').disabled = false;",
      :update  => 'lbContent', :html => { :onKeyPress => 'return checkEnter(event);' } }.merge( opts )

    form_remote_tag options
  end

  def submit_button( text = "Ok", options = {} )
    opts = { :disabled => false,        
             :class    => 'disabled', 
             :id       => 'add_button' }.merge( options )
    submit_tag text, opts
  end

  def close_box_button( text = "Close" )
    button_to_function text.t, 'box.deactivate()' 
  end

  def display_attribute( object, method, type = 'string', options = {} )
    item = self.instance_variable_get("@#{object.to_s}")
    if item.attribute_frozen?( method ) or (item.frozen? if options[:check_status_self])
      content_tag 'span', item.send( method )
    else
      if not item.errors.empty? and not item.errors[method].nil?
        options['class'] = 'formError'
      end
      case type 
        when 'enum'
          select object, method, options[:choices], options
        else
          text_field object, method, options
      end
    end
  end

  def edit_freeze_state( object, attribute )
    if object.attribute_freezable?( attribute ) and not object.new_record?
      if object.attribute_frozen?( attribute )
        content_tag 'div', unfreeze_attribute_link(object, attribute), :class => 'freeze' 
      else
        content_tag 'div', freeze_attribute_link(object, attribute), :class => 'freeze'
      end
    end if editor?
  end

  def freeze_attribute_link( object, attribute )
    html_id = "freeze_#{object.class.to_s.downcase}_#{object.id}_#{attribute}"
    text    = "Prevent Users from changing the attribute: %s" / attribute
    link_to_remote content_tag(:span, text),
        { :url => { :controller => object.class.base_class_name.underscore,
                    :action     => :freeze_attribute,
                    :object     => object.class.base_class_name.underscore,
                    :attribute  => attribute,
                    :id         => object.id },
          :success => "Element.replace('#{html_id}', '" + unfreeze_icon + "')",
          :failure => "Element.replace('#{html_id}', '" + freeze_icon + "')",
          :loading => "Element.update('#{html_id}', '" + loading_image + "')" },
        { :title   => text,
          :class   => 'freeze_link',
          :id      => html_id }
  end

  def unfreeze_attribute_link( object, attribute )
    html_id = "freeze_#{object.class.to_s.downcase}_#{object.id}_#{attribute}"
    text    = "Allow Users to change the attribute: %s" / attribute
    link_to_remote content_tag(:span, text), 
        { :url => { :controller => object.class.base_class_name.underscore,
                    :action     => :unfreeze_attribute,
                    :object     => object.class.base_class_name.underscore,
                    :attribute  => attribute,
                    :id         => object.id },
          :success => "Element.replace('#{html_id}', '" + freeze_icon + "')",
          :failure => "Element.replace('#{html_id}', '" + unfreeze_icon + "')",
          :loading => "Element.update('#{html_id}', '" + loading_image + "')" },
        { :title   => text,
          :class   => 'unfreeze_link',
          :id      => html_id }
  end
  
  def sort_name_alias_link( object )
    id = "link-sort-name_aliases-" + object.class.to_s.downcase + "-" + object.id.to_s 
    link_to_remote "sort".t,
                  { :url => { :controller => object.class.base_class.to_s.downcase, 
                              :action => "activate_name_alias_sorting", 
                              :type => "name_aliases-" + object.class.to_s.downcase + "-" + object.id.to_s } },
                  { :id    => id,
                    :title => "Sort this list".t,
                    :class => "edit-button" }
  end

  def sort_icon_div
    content_tag 'div', sort_icon, :class => 'freeze handle'
  end

  def arrow_down_div( parent )
    content_tag 'div', arrow_down_icon( :alt => "This Cast has been inherited from ".t + local_title_for(parent) ), :class => 'freeze'
  end
  
  def more_information_help_text
    content_tag 'div', "hover over an element in the above list box to receive more information".t, :class => 'help-text'
  end
  
  def livesearch_filter_frequency
    0.4
  end

end
