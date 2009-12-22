require 'application'

module CalculatePopularities
  def self.calculate
    popularities_filename = "/var/log/apache2/www.omdb.org/popularity_log.1"
    # popularities_filename = "/tmp/popularity_log"
    popularities = {}
    session_votes = {}
    routes = ActionController::Routing::Routes
    count_popularity_for = [ Movie, Category, Person, Company, Job ]
    regexp = /^\/(movie|person|encyclopedia\/job|encyclopedia\/category|company)/

    open( popularities_filename ).each do |line|
      method, session, path = line.split
      if method != "GET" || session == "-" || path !~ regexp
        next
      end

      params_hash = routes.recognize_path path.split("/")[1..-1]
      if params_hash.nil?
        next
      end
      type = params_hash["controller"].to_s.gsub("Controller","").constantize
      id = params_hash["id"]

      next if !count_popularity_for.include?( type ) || id.nil?

      popularities[type] ||= {}
      popularities[type][id] ||= 1
      session_votes[session] ||= {}
      session_votes[session][type] ||= {}
      unless session_votes[session][type][id]
        popularities[type][id] += 1
        session_votes[session][type][id] = true
      end
    end

    popularities.each { |klass, hash|
      hash.each{ |id, popularity|
        begin
          object = klass.find(id)
        rescue ActiveRecord::RecordNotFound
          next
        end
        puts "(#{object.popularity} + #{popularity}) / 2"
        p = (object.popularity + popularity) / 2
        puts "Setting popularity for #{object.name} to #{p}"
        object.popularity = p
        object.skip_dependent_objects = true
        object.save
      }
    }
  end
end
