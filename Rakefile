# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/switchtower.rake, and they will automatically be available to Rake.
#
require(File.join(File.dirname(__FILE__), 'config', 'boot'))
     
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

desc "Clean up old logs."
task :clean_logs do
  puts "Cleaning up old logs"
  %w{development.log test.log}.each do |log|
    file = "#{RAILS_ROOT}/log/#{log}"
    File.delete(file) if File.exist?(file)
  end
end