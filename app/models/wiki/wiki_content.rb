
module WikiContent

  def html_needs_update?
    return true
    data_html.nil? || data_html.blank? || (30.minutes.ago.utc > html_updated_at)
  end

  def render_textile(data)
    r = OmdbRedCloth.new data
    r.rules = [:block_textile_table, :block_textile_lists,
              :block_textile_prefix, :inline_textile_image, :inline_textile_link,
              :inline_textile_code, :inline_textile_span, :glyphs_textile,
              :block_markdown_setext, :block_markdown_atx, :block_markdown_rule,
              :block_markdown_bq, :block_markdown_lists, :no_span_caps, 
              :inline_markdown_reflink, :inline_markdown_link, :block_markdown_spoil]
    r.to_html(r.rules)
  end

  def generic?
    related_object.nil?
  end

  # overwritten in page.rb to allow renaming of normal pages
  def may_rename?(*args)
    false
  end
end
