class AddMoreVersioning < ActiveRecord::Migration
  def self.up
    NameAlias.create_versioned_table
    Movie.create_versioned_table
    Person.create_versioned_table
    Character.create_versioned_table
    Reference.create_versioned_table
    Cast.create_versioned_table
  end

  def self.down
    NameAlias.drop_versioned_table
    Movie.drop_versioned_table
    Person.drop_versioned_table
    Character.drop_versioned_table
    Reference.drop_versioned_table
    Cast.drop_versioned_table
  end
end
