class AddRenderedHtmlColumnToContents < ActiveRecord::Migration
  def self.up
    [:contents, :content_versions].each do |table|
      add_column table, 'data_html', :text
      add_column table, 'html_updated_at', :datetime
    end
  end

  def self.down
    [:contents, :content_versions].each do |table|
      remove_column table, 'html_updated_at'
      remove_column table, 'data_html'
    end
  end
end
