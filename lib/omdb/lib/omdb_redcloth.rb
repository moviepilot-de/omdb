require 'redcloth'
class OmdbRedCloth < RedCloth

  MARKDOWN_SPOIL_RE = /\A(^ *! ?.+$(.+\n)*\n*)+/m

  def block_markdown_spoil( text )
    text.gsub!( MARKDOWN_SPOIL_RE ) do |blk|
      blk.gsub!( /^ *! ?/, '' )
      flush_left blk
      blocks blk
      blk.gsub!( /^(\S)/, "\t\\1" )
      %{<div class="spoiler">\n#{ blk }\n</div>\n\n}
    end
  end

end
