module TestHelper
  
  def path_links(path)
    html = link_to("coverage/", :action => "coverage", :path => "")
    elements = path.split("/")
    last = elements.pop
    path = ""
    elements.each do |element|
      path << "#{element}/"
      html << link_to("#{element}", :action => "coverage", :path => path) << "/"
    end
    html << last if last
    html
  end
  
  KEYWORDS = [ 'end', 'else', 'rescue' ]
    
  def text_class(text)
    text = text.strip
    cls = "code"
    if text
      if text[0] == 35
        cls = 'comment' 
      elsif KEYWORDS.detect { |kw| text.index(kw) == 0 }
        cls = "def"
      end
    end
    cls
  end

end