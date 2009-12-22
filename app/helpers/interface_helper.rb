module InterfaceHelper
  def frozen(object)
    object.respond_to?(:frozen) ? object.frozen : false
  end

  def sortable_list(klass, member, object, action, options)
    o = { :view       => Inflector.singularize(member) }.merge( options )
    a = { :action     => 'sort_' + klass.to_s + '_' + member.to_s,
          :controller => klass.to_s.downcase + '_ajax' }
    a.update( { :id => object.id } ) unless object.nil?
    a.update(action) unless action.nil?
    
    options = { :handle => 'handle', :url => a }
    ul_id = klass.to_s + "-" + member.to_s
    # ul_id = ul_id + "-" + object.id.to_s unless object.nil?
    html  = "<ul id='#{ul_id}' class='sortable'>"
    if object.nil?
      html += render :partial => o[:view], :collection => Module.const_get(klass.id2name.camelize).send(member)
    else
      html += render :partial => o[:view], :collection => object.send(member)
    end
    html += "</ul>"
    html += sortable_element( ul_id, options )
  end

end
