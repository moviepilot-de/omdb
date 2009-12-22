module MovieFilterHelper
  def start_filter
    [ 'country', 'company', 'category', 'person' ].each { |var|
      if not self.instance_variable_get("@#{var}").nil?
        object = self.instance_variable_get("@#{var}")
        html = "var filters = new QueryFilters('#{var.humanize.t}', '#{var}', "
        html << ((object.class == Category) ? "'#{object.local_name(@language)}', '#{object.id}'" : "'#{object.name}', '#{object.id}'")
	      html << ");"
	      return html
      end
    }
  end
end
