module Wiki
  class WikiWord
    def convert_to_object(match, object, lang, class_type)
      id, page = pattern.match(match).to_a.slice(1,2)
      clazz = class_type.to_s.capitalize.constantize
      begin
        ret = clazz.find(id)
        page, title = page.split("|")
        if page.nil? or page.empty?
          if title.nil? or title.empty?
            ret
          else
            # Setting the movie.display_title to the title set in the WikiWord Section
            # e.g. [[m:1|Please display me]]
            ret.display_title = title
            ret
          end
        else
          if ret.kind_of?(WikiEnabled)
            ret.page( page, lang, title )
          else
            match
          end
        end
      rescue ActiveRecord::RecordNotFound
        match
      end
    end
  end
end
