require 'set'
require 'pp'

module WikiWordRepair
  class <<self

    # repair WikiWords in contents
    def run
      contents = Content.find(:all)
      puts "#{contents.size} contents"
      contents.each_with_index { |content, i| repair_content content, i }
      'success'
    end

    def repair_content(content, i)
      return unless content.data =~ /<a href/
      repaired = content.data.gsub(%r{<a\s+href="(.+?)".*?>(.+?)</a>}) do |match|
        build_wiki_word $1, $2, match, content
      end
      rendered_repaired = replace_wiki_words(:data => repaired, :content => content)
      original = replace_wiki_words(:content => content).gsub('http://omdb.org', 'http://www.omdb.org').gsub('der+Trilogie+"', 'der+Trilogie"').gsub('<a href="/movie/261/edit/Wissenswertes" class="edit">Cat on a Hot Tin Roof :: Wissenswertes</a>', '<a href="http://www.omdb.org/movie/261/wiki/Wissenswertes" class="strong">Wissenswertes</a>').gsub(/<a\s+href="http:\/\/www.omdb.org\/person\/682">Uwe Ochsenknecht<\/a>/, '<a href="http://www.omdb.org/person/682">Uwe Ochsenknecht</a>') # fix some non-critical differences and bugs in rendered version
      if rendered_repaired != original
        puts "difference detected (#{pp_content content}): \n\nSHOULD BE\n#{original}\n\nBUT IS\n#{rendered_repaired}" 
        raise "errors in content #{i}"
      else 
        content.update_attribute :data, repaired
        puts "fixed #{pp_content content}"
      end
    end

    def pp_content(content)
      "page id=#{content.id}, #{content.page_name} #{content.related_object_type} #{content.related_object_id}"
    end

    def replace_wiki_words(options = {})
      data    = (options[:data] || options[:content].data).dup
      content = options[:content]

      [ Wiki::WikiWordPerson, Wiki::WikiWordMovie, Wiki::WikiWordCharacter, Wiki::WikiWordImage, 
        Wiki::WikiWordWiki, Wiki::WikiWordWikipedia, Wiki::WikiWordCompany, Wiki::WikiWordCategory, 
        Wiki::WikiWordEncyclopedia, Wiki::WikiWordGooglemaps ].each { |klass|
        w = klass.new
        if options[:limit]
          data = data.slice(0, options[:limit]).gsub(/\[\[i:[^\]]+\]\]/,'').split(/ /)
          data.pop
          data = data.join(" ") + " ..."
        end
        data.gsub!(w.pattern) { |match|
          object = w.to_o( match, content.related_object, content.language)
          if object.class == "String".class
            # The WikiWord did not match to an object, the String that triggered
            # the WikiWord will be displayed.
            # e.g.
            # [[i dont exist]] or [[m:99999999999999]]
            object
          elsif object.class == Image
            puts "image in content #{pp_content content}: #{match} "
            "<img src=\"/image/#{object.id}/wiki\" />" # wir rendern hier nur zum vergleich, also ist's eigentlich egal
          else
            # Ein Objekt wurde gefunden, auf das Verlinkt werden soll.
            # Nur Wiki-Objekte (WikiWordWiki) unterstuetzen neue Objekte,
            # daher trifft der erste Block nur fuer WikiWordWikis zu.
            if object.new_record?
              object.language = content.language
              controller = content.related_object.class.base_class.to_s.downcase
              "<a href=\"/#{controller}/#{object.related_object_id}/edit/#{url_escape object.page_name}\" class=\"edit\">#{object.related_object.name} :: #{object.page_name}</a>"
            else
              # Jedes Objekt hat eine default action, welche die einfache
              # Darstellung des Objekts erlaubt. Etwas kompliziertes ist
              # es bei WikiPages, welche prinzipiell ueberall sein koennten.
              if object.class == Page
                link_to_object object, content, 'strong'
              else
                link_to_object object, content
              end
            end
          end
        }
      }
      data
    end

    def url_unescape(string)
      string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
        [$1.delete('%')].pack('H*')
      end
    end
    def url_escape(string)
      string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.tr(' ', '+')
    end

    def link_to_object( object, content, style = nil )
      if object.respond_to?("display_title")
        title = object.display_title
      end
    
      if title.nil? or title.empty?
        title = local_title_for object, content
      end

      controller = object.class.base_class.to_s.downcase
      controller = controller.split("::").last if controller =~ /::/
      url = case object
      when Content
        controller = object.related_object.class.base_class.to_s.downcase         
        { :only_path => false, :controller => controller, :action => "wiki", :page => object.page_name, :id => object.related_object.id }
      when Image
        raise "Image ?!"
      else
        { :only_path => false, :controller => controller, :action => "index", :id => object.id }
      end
 
      controller = "encyclopedia/#{controller}" if controller =~ /^category$/ && !url[:page]
      href = "#{controller}/#{url[:id]}"
      href << "/wiki/#{url_escape url[:page]}" if url[:page]
      clazz = style.nil? ? '' : %{ class="#{style}"}
      %{<a href="http://www.omdb.org/#{href}"#{clazz}>#{title}</a>}
    end

    def local_title_for(o, content)
      language = content.language
      title = o.name
      if o.respond_to?("display_title")
        title = o.display_title
      end 
      return title unless title.to_s.blank?
        
      if o.is_a?(Page)
        title = local_title_for_page(o, language, content)
      elsif o.is_a?(Movie)
        title = local_title_for_movie(o, language)
      elsif o.respond_to?(:local_name)
        title = o.send(:local_name, language)
      end
      return title unless title.to_s.blank?
      o.name
    end

    def local_title_for_page(page, lang, content)
      return page.display_title unless page.display_title.to_s.blank?
      
      if not content.nil? and content.related_object == page.related_object
        page.page_name
      else
        page.name
      end
    end

    def local_title_for_movie(movie, lang)
      if movie.display_title.to_s.blank?
        a = movie.aliases.local lang
        a.empty? ? nil : a.first.name
      else
        movie.display_title
      end
    end


    def build_wiki_word(href, value, match, content)
      
      @unresolved_hrefs ||= Set.new
      @wikipedia ||= Set.new
      @maps ||= Set.new

      host = 'omdb.org'
      path = href
      if href =~ %r{http://([^/]+)(.+)}
        host, path = $1, $2
      end

      case host
      when /omdb\.org/
        case path 
        when %r{^/movie/(\d+)/(wiki|edit)/(.+)$}
          id, page = $1, $3
          #puts "Movie-Page: #{id}, #{page}"
          if id.to_i == content.related_object_id
            page = url_unescape(page).strip
            value.strip != page && $2 !~ /edit/ ? "[[#{page}|#{value}]]" : "[[#{page}]]"
          else
            puts "foreign movie page"
            m = Movie.find(id)
            value !~ /::/ && $2 !~ /edit/ ? "[[m:#{id}:#{url_unescape page}|#{value}]]" : "[[m:#{id}:#{url_unescape page}]]"

          end
        when %r{^/person/(\d+)$}
          id = $1
          #puts "Person: #{id}"
          value == local_title_for(Person.find(id), content) ? "[[p:#{id}]]" : "[[p:#{id}|#{value}]]"
        when %r{^/character/(\d+)$}
          id = $1
          #puts "Character: #{id}"
          value == local_title_for(Character.find(id), content) ? "[[ch:#{id}]]" : "[[ch:#{id}|#{value}]]"
        when %r{^/character/(\d+)/(wiki|edit)/(.+)$}
          id, page = $1, $3
          #puts "Character Page: #{id}, #{page}"
          if id.to_i == content.related_object_id
            value != url_unescape(page) && $2 !~ /edit/ ? "[[#{url_unescape page}|#{value}]]" : "[[#{url_unescape page}]]"
          else
            puts "foreign character page"
          end
        when %r{^/encyclopedia/category/(\d+)$}
          id = $1
          value == local_title_for(Category.find(id), content) ? "[[ca:#{id}]]" : "[[ca:#{id}|#{value}]]"
          #puts "Encyclopedia/category: #{id}"
        when %r{^/company/(\d+)$}
          id = $1
          value == local_title_for(Company.find(id), content) ? "[[co:#{id}]]" : "[[co:#{id}|#{value}]]"
          #puts "Company: #{id}"
        when %r{^/movie/(\d+)$}
          id = $1
          #puts "Movie: #{id}"
          value == local_title_for(Movie.find(id), content) ? "[[m:#{id}]]" : "[[m:#{id}|#{value}]]"
        when %r{^/category/(\d+)/wiki/(.+)$}
          id, page = $1, $2
          #puts "category page: #{id}, #{page}"
          if id.to_i == content.related_object_id
            value != url_unescape(page) && $2 !~ /edit/ ? "[[#{url_unescape page}|#{value}]]" : "[[#{url_unescape page}]]"
          else
            puts "foreign category page"
          end
        else 
          @unresolved_hrefs << href
          match
        end
      when /wikipedia\.org/
        #@wikipedia << path
        #"WIKIPEDIA: #{match}"
        if path =~ /\/?wiki\/(.+)$/
          "[[wp:#{$1}]]"
        else
          puts "illegal wp path ?"
        end
      when /maps\.google\.com/
        #@maps << path
        #"GMAPS: #{match}"
        if path =~ /\/\?q=(.+)$/
          value != $1 ? "[[gm:#{$1}|#{value}]]" : "[[gm:#{$1}]]"
        else
          puts "illegal gm path ?"
        end
      else
        @unresolved_hrefs << href
        "FIXME: #{match}"
      end
    end

    def test
      run
      pp @unresolved_hrefs unless @unresolved_hrefs.empty?
      puts "maps: #{@maps.size}"
      puts "wikipedia: #{@wikipedia.size}"
    end

  end

end
