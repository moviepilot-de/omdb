require 'diff'

module Wiki
  module WikiHelper
    include HTMLDiff
    include ImageHelper
    
    def replace_wiki_words(options = {})
      data    = (options[:data] || options[:content].data).dup
      content = options[:content]

      # filter out images for toc and index pages
      if options[:limit] || (content && content.page_name == 'index')
        data = data.gsub(/\[\[i:[^\]]+\]\]/,'')
      end
      # shorten content for toc
      if options[:limit]
        data = data.slice(0, options[:limit]).split(/ /)
        data.pop
        data = "#{data.join ' '} ..."
      end

      [ WikiWordPerson, WikiWordMovie, WikiWordCharacter, WikiWordImage, 
        WikiWordWikipedia, WikiWordCompany, WikiWordCategory, 
        WikiWordEncyclopedia, WikiWordGooglemaps, WikiWordWiki, EscapedWikiWord ].each { |klass|
        w = klass.new
        data.gsub!(w.pattern) { |match|
          object = w.to_o( match, content.related_object, @language )
          case object
            when String
              # The WikiWord did not match to an object, the String that triggered
              # the WikiWord will be displayed.
              # e.g.
              # [[i dont exist]] or [[m:99999999999999]]
              # also applies to escaped wiki words such as [[!ch:152]], which
              # will be displayed as [[ch:152]]
              object
            when Image
              content_tag("div",
                content_tag("div", 
                    db_image_tag(object, :action => :wiki, :alt => object.display_title) +
                    content_tag("span", object.display_title.nil? ? "default value" : object.display_title),
                    :class => 'image-box'),
                :class => 'image-anchor') + "\n\n"
            else
              # Ein Objekt wurde gefunden, auf das Verlinkt werden soll.
              # Nur Wiki-Objekte (WikiWordWiki) unterstuetzen neue Objekte,
              # daher trifft der erste Block nur fuer WikiWordWikis zu.
              if object.new_record?
                object.language = @language
                link_to_object object, 'edit'
              else
                # Jedes Objekt hat eine default action, welche die einfache
                # Darstellung des Objekts erlaubt. Etwas kompliziertes ist
                # es bei WikiPages, welche prinzipiell ueberall sein koennten.
                if Page === object
                  link_to_object object, 'strong'
                else
                  link_to_object object
                end
              end
          end
        }
      }
      data
    end

    def render_wiki_content(options)
      content = options[:content]
      options[:data] ||= content.data
      content.render_textile replace_wiki_words(options)
    end
    
    def display_wiki_content(content, default_text = nil)
      if content
        content.data_html = render_wiki_content(:content => content)
        if content.data_html.empty? and related_object.may_edit_pages(current_user)
          if default_text.nil?
            return content_tag( :p, "no article has been created yet, you can %s"/(edit_link( content, "start&nbsp;one", nil )), :class => 'empty' )
          else
            return content_tag( :p, default_text, :class => 'empty' )
          end
        else
          if content.data_html.empty?
            content_tag( :p, default_text, :class => 'empty' ) unless default_text.nil?            
          else
	    content.save_content_cache( content.data_html ) if content.html_needs_update?
            return content.data_html
          end
        end
      else
        content_tag( :p, default_text, :class => 'empty' ) unless default_text.nil?
      end
    end
    
    # converts a version number to a list of numbers from 1 to the specified version number
    def versions_as_list(version)
      versions = []
      if not version.nil?
        1.upto(version) {|i| versions << i}
      end
      versions
    end
    
    # calculates the wiki diff between two versions of content
    def display_diff(version1, version2)
      version1_text = render_wiki_content(:content => version1)
      version2_text = render_wiki_content(:content => version2)
      diff(version1_text, version2_text)
    end
    
    def local_title_for_page(page)
      if not ( page.display_title.nil? or page.display_title.empty? )
        return page.display_title
      end
      
      if not @page.nil? and @page.related_object.id == page.related_object.id and
         @page.related_object.class == page.related_object.class
        page.page_name
      else
        page.name
      end
    end
    
    def edit_or_view_subpage
      (params[:action] == 'page' or params[:action] == 'edit_page') and not @page.nil? and not @page.page_name == "index"
    end
  end
end
