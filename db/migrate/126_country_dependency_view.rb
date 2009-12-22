class CountryDependencyView < ActiveRecord::Migration
  def self.up
    execute "drop view IF EXISTS country_dependencies_view"
    execute "create view country_dependencies_view as 
      SELECT globalize_countries.id as id,
        (select group_concat(movie_countries.movie_id) from movie_countries where globalize_countries.id = movie_countries.country_id) as 'Movie'
      from globalize_countries"
  end

  def self.down
    execute "drop view IF EXISTS country_dependencies_view"
  end
end
