module JavascriptHelper

  def create_wiki_add_function( type )
    text =  "add_#{type} = function(id) {"
    text << "  url = '/#{type}/' + id + '/info?size=2&wiki_request=true';"
    text << "  id  = '#{type}-information';"
    text << "  Element.update(id, '<div class=\"loading\">&nbsp;</div>');";
    text << "  request = new Ajax.Updater(id, url, {asynchronous:true});" 
    text << "}"
  end

  def create_add_function( type, allow_dublicates = false )
    text =  "add_#{type} = function(id) {"
    text << "  #{type} = 'search-#{type}-' + id;"
    text << "  new_id   = 'movie-#{type}-' + id;"
    text << "  if (!$(new_id)) {" unless allow_dublicates
    text << "    var element  = $(#{type}).cloneNode(true);"
    text << "    var link     = element.getElementsByTagName('a')[0];"
    text << "    var input    = element.getElementsByTagName('input')[0];"
    text << "    element.id   = new_id;"
    text << "    input.name   = \"#{type.to_s.pluralize}[]\";"
    text << "    link.onclick = function() { remove_#{type}(id); return false; };"
    text << "    Element.addClassName( link, 'edit' );"
    text << "    $('selected_#{type.to_s.pluralize}').appendChild(element);"
    text << "    $('filter_#{type.to_s.pluralize}').focus();"
    text << "  }" unless allow_dublicates
    text << "  Element.remove( #{type} );";
    text << "}"
  end

  def create_remove_function( type )
    text =  "remove_#{type} = function(id) {"
    text << "  #{type} = 'movie-#{type}-' + id;"
    text << "  new_id  = 'search-#{type}-' + id;"
    text << ""
    text << "  var element  = $(#{type}).cloneNode(true);"
    text << "  var link     = element.getElementsByTagName('a')[0];"
    text << "  var input    = element.getElementsByTagName('input')[0];"
    text << "  element.id   = new_id;"
    text << "  input.name   = \"search_result[]\";"
    text << "  link.onclick = function() { add_#{type}(id); return false; };"
    text << "  removeEmptyListItem('searched_#{type.to_s.pluralize}');"
    text << "  Element.removeClassName( link, 'edit' );"
    text << "  Element.remove( #{type} );"
    text << "  $('searched_#{type.to_s.pluralize}').appendChild(element);"
    text << " }"
  end

  def create_add_new_function( type )
    text =  "add_new_#{type} = function() {\n"
    text << "  if ( $('filter_#{type.to_s.pluralize}').value.length > 2 ) {\n"
    text << "    var text      = $('filter_#{type.to_s.pluralize}').value.strip();\n"
    text << "    var id        = text.replace(/\\s/, '_');"
    text << "    #{type}_id    = 'new-#{type}-' + id;\n"
    text << "    var element   = create_li( #{type}_id );\n"
    text << "    var hidden    = create_hidden_field( \"new_#{type.to_s.pluralize}[]\", text );\n"
    text << "    var textNode  = document.createTextNode( text + \" (will be created)\" );\n"
    text << "    var link      = create_a( textNode );\n"
    text << "    link.onclick  = function() { Element.remove(#{type}_id); return false; };"
    text << "    link.className = 'edit';"
    text << "    if (!$(#{type}_id)) {\n"
    text << "      element.appendChild( hidden );"
    text << "      element.appendChild( link );"
    text << "      $('selected_#{type.to_s.pluralize}').appendChild(element);"
    text << "    }\n"
    text << "  }"
    text << "}"
  end
  
  def create_small_tabs_navigation( tab_names, fields_to_activate = {} )
    text =  "active_tab = '#{tab_names.first.to_s}';\n"
    text << "display_tab = function(id) {\n"
    text << "  Element.hide('tab_' + active_tab);\n"
    text << "  Element.removeClassName('tab_link_' + active_tab, 'active');\n\n"
    text << "  active_tab = id;\n\n"
    text << "  Element.show('tab_' + active_tab);\n"
    text << "  Element.addClassName('tab_link_' + id, 'active');\n"

    tab_names.each do |tab_name|
      next if fields_to_activate[tab_name].nil?
      text << "  if (id == '#{tab_name.to_s}') {\n"
      text << "    $('#{fields_to_activate[tab_name]}').focus();\n"
      text << "  }\n"
    end

    text << "}\n"
    
    unless fields_to_activate[tab_names.first].nil?
      text << "if ( $('#{fields_to_activate[tab_names.first]}') != undefined ) { $('#{fields_to_activate[tab_names.first]}').focus(); }\n"
    end

    text
  end

end
