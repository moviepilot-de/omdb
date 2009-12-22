module SearchHelper
  def auto_complete_result(entries, field, phrase = nil)
    if entries != []
      if ["MovieSeries", "Series", "Episode"].include?(entries[0].class.to_s)
        template = "movie_search_result"
      else
        template = entries[0].class.to_s.downcase + '_search_result'
      end
      content_tag "ul", render( :partial => template, :collection => entries )
    end
  end
  
  def other_categories
    return [] unless @categories
    @categories.map { |c|
      c.root unless c.root == Category.plot_keyword
    }.compact.uniq
  end
  
  def link_to_category_tab( category )
    tab = category.base_name
    js_code = "$('filter_#{tab.pluralize}').value = '#{@filter}'; display_tab('#{tab}');"
    link_to_function category.local_name(@language), js_code, :class => 'plain'
  end
  
  # try to use lazydoc to fetch local names, fall back to sql, if no local name available
  def local_name( object, lang )
    name = ((lang == Locale.base_language) ? object[:name] : object["name_#{lang.code}".to_sym])
    name = object.local_name( lang ) if name.nil?
    return name
  end
  
end
