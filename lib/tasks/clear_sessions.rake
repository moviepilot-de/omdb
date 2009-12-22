# We're not using tmp:sessions:clear as this would
# remove all sessions, but we want active sessions
# to stay alive...
require 'fileutils'
require 'find'

namespace :omdb do
  namespace :sessions do
    task :clear => :environment do
      session_store = ActionController::Base.session_options[:tmpdir]
      Find.find(session_store) do |file|
        rm file if File.mtime(file) < 2.hours.ago and File.basename(file) =~ /ruby_sess/
      end
    end
  end
end