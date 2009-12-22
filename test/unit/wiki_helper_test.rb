require File.dirname(__FILE__) + '/../test_helper'

class WikiHelperTest < HelperTestCase
  fixtures :characters, :contents, :users, :globalize_languages, :images

  include ApplicationHelper
  include Wiki::WikiHelper

  def setup
    super
    @language = Locale.base_language
    assert_difference Page, :count do
      @content = Page.create!(:data => "Star-wars rocks", 
                              :related_object => users(:quentin), 
                              :user => users(:quentin),
                              :language => Locale.base_language,
                              :page_name => "MyPage")
    end
  end

  def test_keep_version_created_at
    content = Page.create!(:data => "link : [[Imprint]]", 
                           :language => Locale.base_language, 
                           :page_name => 'generic test')
    assert_equal 1, content.version
    content.data = 'new version'
    content.accept_license_and_save!
    content.reload
    assert_equal 2, content.version

    old = content.find_version(1)
    assert Content::Version === old
    assert_equal 1, old.version
    old_created_at = old.created_at

    sleep 1
    display_wiki_content old
    old.reload
    assert_equal old_created_at, old.created_at
  end

  def test_link_to_generic_page
    content = Page.create!(:data => "no link", 
                           :language => Locale.base_language, 
                           :page_name => 'generic test')

    assert_match %r{<a href="/content/Imprint" class="strong" title=".*">Imprint</a>}, 
                 replace_wikiwords("link : [[Imprint]]", content)
  end

  def test_link_to_help_page_with_displaytitle
    content = Page.create!(:data => "no link", 
                           :language => Locale.base_language, 
                           :page_name => 'generic test')

    assert_match %r{<a href="/content/Help%3ASubpage1" class="edit" title=".*">Link zu einer Unterseite</a>}, 
                 replace_wikiwords("link : [[Help:Subpage1|Link zu einer Unterseite]]", content)
  end

  def test_link_to_help_page
    content = Page.create!(:data => "no link", 
                           :language => Locale.base_language, 
                           :page_name => 'generic test')

    assert_match %r{<a href="/content/Help%3ASubpage1" class="edit" title=".*">Help:Subpage1</a>}, 
                 replace_wikiwords("link : [[Help:Subpage1]]", content)
  end

  def test_do_not_link_to_character
    assert_match %r{\[\[ch:15\]\]}, 
                 replace_wikiwords("link : [[!ch:15]]")
  end

  def test_no_images_in_index_pages
    index_page = contents(:starwars_index)
    image_tag = "[[i:#{images(:image).id}]]"
    assert_match /img/, replace_wikiwords("image: #{image_tag}", @content)
    assert_no_match /img/, replace_wikiwords("image: #{image_tag}", index_page)
  end

  def test_link_to_character
    assert_match %r{<a href="/encyclopedia/character/15" title=".*"> James T. Kirk</a>}, 
                 replace_wikiwords("link : [[ch:15]]")
    assert_match %r{<a href="/encyclopedia/character/15" title=".*">James Kirk</a>}, 
                 replace_wikiwords("link with alternate title: [[ch:15|James Kirk]]")
  end

  def test_link_to_existing_character_page
    assert_match %r{<a href="/encyclopedia/character/15/page/Additional\+Page\+1" class="strong" title=".*"> James T. Kirk :: Additional Page 1</a>},
                 replace_wikiwords("link : [[ch:15:Additional Page 1]]")
    assert_match %r{<a href="/encyclopedia/character/15/page/Additional\+Page\+1" class="strong" title=".*">Alternate Name</a>},
                 replace_wikiwords("link with alternate title: [[ch:15:Additional Page 1|Alternate Name]]")
  end

  def test_wikipedia_link
    assert_match %r{Mehr Informationen zu <a href="http://en.wikipedia.org/wiki/Berlin" class="external">Berlin</a>},
                 replace_wikiwords("Mehr Informationen zu [[wp:Berlin]]")
  end

  def test_googlemaps_link
    assert_match %r{Karte von <a href="http://maps.google.com/\?q=Berlin" class="external">Berlin</a>},
                 replace_wikiwords("Karte von [[gm:Berlin]]")
  end


  def test_link_to_new_character_page
    assert_match %r{<a href="/encyclopedia/character/15/page/New\+Page" class="edit" title=".*"> James T. Kirk :: New Page</a>},
                 replace_wikiwords("link : [[ch:15:New Page]]")
    assert_match %r{<a href="/encyclopedia/character/15/page/New\+Page" class="edit" title=".*">New Kirk Page</a>},
                 replace_wikiwords("link with alternate title: [[ch:15:New Page|New Kirk Page]]")
  end

  protected
    def replace_wikiwords(data, content=@content)
      content.data = data
      content.accept_license_and_save!
      replace_wiki_words :content => content
    end
end

