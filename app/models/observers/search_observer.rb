# TODO  to keep the knowledge about what to index when in one place, move the entire code here
# into the indexer. Here only call Indexer.object_saved and Indexer.object_destroyed.
#
# Next we should split the indexer up into a class doing the (local) indexing,
# one deciding between local and remote indexing,
# and one knowing what to index/remove when...
# ideally only the class concerned with the real (local) ferret indexing should
# be concerned about the dependencies defined below and in Indexer itself
#
# so we would have these dependencies: 
# Indexer ----TEST----> LocalIndexer --> DependencyGuard (or whatever we call that ;-)
#                                    --> Ferret API
#         -PROD/DEVEL-> IndexWorker  --> LocalIndexer ... as above
#
# having LocalIndexer and IndexWorker share the same API would make sense...
# Indexer itself would be the only public API for use in the rest of the App
#   maybe even just a proxy in front of a LocalIndexer/IndexWorker instance ?
class SearchObserver < ActiveRecord::Observer
  observe MovieSeries, Movie, Series, Season, Episode, 
          Person, Category, NameAlias, Company, Character, Job, Department, Country, 
          MovieUserCategory, Cast, Actor, ProductionCompany, Vote, Content, Abstract, Page,
          Reference, Influence, Remake, Parody, SpinOff, Homage, Trailer

  def benchmark(msg)
    start = Time.now
    yield
    time = Time.now - start
    LOGGER.info sprintf(msg, time)
  end

  LOGGER = Logger.new("#{RAILS_ROOT}/log/search_observer.log")

  def after_save( record )
    return if record.respond_to?(:skip_indexing) && record.skip_indexing

    if record.respond_to?( :skip_dependent_objects ) && record.skip_dependent_objects
      objects = { record.base_class_name => [ record.id ] }
      Indexer.index_object record.to_hash_args
    else
      objects = record.dependent_objects
      Indexer.index_dependencies record.to_hash_args
    end
    objects.each do |class_name, id_array|
      # TODO: ein bulk-expire_object a la expire_objects(type, id_array) waere nett.
      id_array.each do |id|
        next if id == 0
        PageCacheSweeper.instance.expire_object :type => class_name, :id => id
      end
    end
  end
  
  # precalculate dependencies, as we're not able to get the dependencies, once the
  # element is destroyed.
  def before_destroy( record )
    return if record.respond_to?( :skip_dependent_objects ) && record.skip_dependent_objects
    objects = record.dependent_objects
    objects[record.base_class_name].delete(record.id) if objects[record.base_class_name]
    record.instance_variable_set :@before_destroy_dependent_objects, objects
  end

  def after_destroy(record)
    # first remove the object from the index
    args = record.to_hash_args
    Indexer.delete_object args
    PageCacheSweeper.instance.expire_object args

    # then process all dependencies and reindex them all
    objects = record.instance_variable_get :@before_destroy_dependent_objects
    # TODO: ein bulk-enqueue a la index_objects(type, id_array) waere nett.
    objects.each do |class_name, id_array|
      id_array.each do |id|
        next if id == 0
        Indexer.index_object :type => class_name, :id => id
        PageCacheSweeper.instance.expire_object :type => class_name, :id => id
      end
    end

  end

end
