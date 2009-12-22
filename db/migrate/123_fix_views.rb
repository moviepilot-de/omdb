class FixViews < ActiveRecord::Migration
  def self.up
    execute "drop view IF EXISTS movie_dependencies_view"
    execute "create view movie_dependencies_view as 
      SELECT movies.id as id,
        (select group_concat(distinct category_id) from movie_user_categories where movies.id = movie_user_categories.movie_id) as 'Category',
        (select group_concat(company_id) from production_companies where movies.id = production_companies.movie_id) as 'Company',
        (select group_concat(movie_countries.country_id) from movie_countries where movies.id = movie_countries.movie_id) as 'Country',
        (select group_concat(distinct character_id) from casts where movies.id = casts.movie_id) as 'Character',
        (select group_concat(distinct person_id) from casts where movies.id = casts.movie_id) as 'Person'
        from movies"
    
    execute "drop view IF EXISTS person_dependencies_view"
    execute "create view person_dependencies_view as 
      SELECT people.id as id,
        (select group_concat(distinct movie_id) from casts where people.id = casts.person_id) as 'Movie'
      from people"

    execute "drop view IF EXISTS category_dependencies_view"
    execute "create view category_dependencies_view as 
      SELECT categories.id as id,
        (select group_concat(distinct movie_id) from movie_user_categories where categories.id = movie_user_categories.category_id) as 'Movie'
      from categories"

    execute "drop view IF EXISTS company_dependencies_view"
    execute "create view company_dependencies_view as
      SELECT companies.id as id,
        (select group_concat(distinct movie_id) from production_companies where companies.id = production_companies.company_id) as 'Movie'
      from companies"

    execute "drop view IF EXISTS character_dependencies_view"
    execute "create view character_dependencies_view as
      SELECT characters.id as id,
        (select group_concat(distinct movie_id) from casts where characters.id = casts.character_id) as 'Movie'
      from characters"
  end

  def self.down
  end
end
