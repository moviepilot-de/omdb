require File.dirname(__FILE__) + '/../test_helper'

class WikiContentTest < HelperTestCase

  include WikiContent

  def test_quote
    assert_match %r{<blockquote>\s*<p>This is a quote.</p>\s*</blockquote>}, 
                 render_textile("\n> This is a quote.\n")

  end

  def test_spoiler
    assert_match %r{<div class="spoiler">\s*<p>This is a spoiler.</p>\s*</div>}, 
                 render_textile("\n! This is a spoiler.\n")
  end

  def test_spoiler_quote
    assert_match %r{<div class="spoiler">\s*<blockquote>\s*<p>This is a spoiling quote.</p>\s*</blockquote>\s*</div>}, 
                 render_textile("\n! > This is a spoiling quote.\n")
  end


end

