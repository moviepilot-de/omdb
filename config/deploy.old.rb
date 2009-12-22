# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

require 'socket'

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "omdb"
set :repository, "https://svn.omdb-beta.org/trunk"

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

# deploy to omdb.org with
#   rake remote:deploy_to_livesystem
#   this will trigger a 'rake remote:deploy' on omdb-beta.org (aka mail.omdb.org),
#   which will deploy on omdb.org. You are not allowed to deploy to omdb.org
#   directely, as ssh-connections to omdb.org are only allowed from omdb-beta.org 
# deploy to omdb-beta.org with 
#   rake deploy
if Socket.gethostname == "mail.omdb.org"
  role :web, "homer.omdb.org"
  role :app, "homer.omdb.org"
  role :drb, "homer.omdb.org"
  role :db, "homer.omdb.org", :primary => true
else
  role :web, "mail.omdb.org"
  role :app, "mail.omdb.org"
  role :drb, "mail.omdb.org"
  role :db,  "mail.omdb.org", :primary => true
end

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, "/var/www/localhost/rails"
set :user, "rails"            # defaults to the currently logged in user
set :use_sudo, false
set :spawn_instances, 10

# set :scm, :darcs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway

# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:keys] = %w( /var/www/localhost/rails/.ssh/id_rsa /home/benjamin/.ssh/id_dsa /home/jk/.ssh/id_dsa /Users/benjamin/.ssh/id_dsa )

# ssh_options[:port] = 25

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

desc "Just a simple test task"
task :hostname do
  run "hostname"
end

desc "Restart the mongrel cluster"
task :restart, :roles => :app do
  restart_backgroundrb
  sudo '/etc/init.d/mongrel_cluster restart'
end

desc "Deploy current version to omdb.org"
task :deploy_to_livesystem, :roles => :app do
  run "cd #{current_path}; rake remote:deploy"
  run "cd #{current_path}; rake remote:migrate"
  run "cd #{current_path}; rake remote:cleanup"  
end

# custom spinner task, since capistrano uses the old spin script
desc "Spinner task that uses the spawner script instead of spinner to just start up the FCGI processes."
task :spinner, :roles => :app do
  start_backgroundrb
  sudo "/etc/init.d/mongrel_cluster start"
end

desc 'Stop the backgroundrb server'
task :stop_backgroundrb , :roles => :drb do
  run "#{current_path}/script/backgroundrb/stop"
end

desc 'Start the backgroundrb server'
task :start_backgroundrb , :roles => :drb do
  run "nohup #{current_path}/script/backgroundrb/start -e production -d > /dev/null 2>&1"
end

desc 'Start the backgroundrb server'
task :restart_backgroundrb , :roles => :drb do
  stop_backgroundrb
  start_backgroundrb
end


desc "Task to create a symlink to the shared database configuration, expected to exist in :deploy_to/shared/config"
task :after_update_code do
  run "rm -f #{release_path}/config/database.yml && ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
  run "rm -f #{release_path}/config/backgroundrb.yml && ln -nfs #{deploy_to}/#{shared_dir}/config/backgroundrb.yml #{release_path}/config/backgroundrb.yml"
#  run "rm -rf #{release_path}/db/ferret.index.production && ln -nfs #{deploy_to}/#{shared_dir}/db/ferret.index.production #{release_path}/db/ferret.index.production"
  run "mv #{current_path}/db/ferret.index.production.* #{release_path}/db/"
  run "ln -nfs #{release_path}/bin/qtinfo.linux #{release_path}/bin/qtinfo"
  run "rm -rf #{release_path}/tmp/sessions && ln -nfs #{deploy_to}/#{shared_dir}/tmp/sessions #{release_path}/tmp/sessions"
  # run "rm -rf #{release_path}/public/image && ln -nfs #{deploy_to}/#{shared_dir}/public/image #{release_path}/public/image"
end

desc "clears the image cache"
task :clear_image_cache, :roles => :app do
  run "rm -fr #{shared_path}/public/image/*"
end

desc "Takes the current running application's ferret index and puts it into the shared directory. Should only be run once."
task :share_image_cache, :roles => :app do
  run <<-CMD
    mkdir -p #{deploy_to}/#{shared_dir}/public/image && \
    chmod g+w #{deploy_to}/#{shared_dir}/public/image && \
    rm -fr #{current_path}/public/image && \
    ln -nfs #{deploy_to}/#{shared_dir}/public/image #{current_path}/public/image
  CMD
end

desc "Takes the current running application's ferret index and puts it into the shared directory. Should only be run once."
task :share_index, :roles => :app do
  run <<-CMD
    mkdir -p #{deploy_to}/#{shared_dir}/db && \
    mv #{current_path}/db/ferret.index.production.online #{deploy_to}/#{shared_dir}/db/ && \
    mv #{current_path}/db/ferret.index.production.offline #{deploy_to}/#{shared_dir}/db/
  CMD
end

desc "puts the sessions directory into shared/ . Should only be run once."
task :share_sessions, :roles => :app do
  run <<-CMD
    mkdir -p #{deploy_to}/#{shared_dir}/tmp/ && \
    mv #{current_path}/tmp/sessions #{deploy_to}/#{shared_dir}/tmp/ && \
    ln -nfs #{deploy_to}/#{shared_dir}/tmp/sessions #{current_path}/tmp/sessions
  CMD
end

desc "Recreate object index for ferret"
task :reindex, :roles => :app do
  shutdown
  run "mkdir -p #{deploy_to}/#{shared_dir}/db/ferret.index.production"
  send(run_method, "cd #{current_path} && rake RAILS_ENV=production reindex")
  spinner
end

desc "Shuts down the FastCGI processes"
task :shutdown, :roles => :app do
  send(run_method, "#{current_path}/script/process/reaper -a graceful")
end

desc <<DESC
An imaginary backup task. (Execute the 'show_tasks' task to display all
available tasks.)
DESC
task :backup, :roles => :db, :only => { :primary => true } do
  # the on_rollback handler is only executed if this task is executed within
  # a transaction (see below), AND it or a subsequent task fails.
  on_rollback { delete "/tmp/dump.sql" }

  run "mysqldump -u theuser -p thedatabase > /tmp/dump.sql" do |ch, stream, out|
    ch.send_data "thepassword\n" if out =~ /^Enter password:/
  end
end

# You can use "transaction" to indicate that if any of the tasks within it fail,
# all should be rolled back (for each task that specifies an on_rollback
# handler).

desc "A task demonstrating the use of transactions."
task :long_deploy do
  transaction do
    update_code
    disable_web
    symlink
    migrate
  end

  restart
  enable_web
end
