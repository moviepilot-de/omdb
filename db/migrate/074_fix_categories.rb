class FixCategories < ActiveRecord::Migration
  def self.up
    Category::CATEGORY_TYPES.each_with_index{ |name, index|
      aliases = Category.find(index + 1).name_aliases.local( Locale.base_language )
      raise if aliases.empty?
      aliases[0].name = name
      aliases[0].save
    }
    Category.term.children.each { |c|
      c.parent = Category.plot_keyword
      c.save
    }
  end

  def self.down
  end
end
