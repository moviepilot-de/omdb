set :application, "OMDB"
set :repository, "https://svn.omdb-beta.org/trunk"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/www.omdb.org/rails"
set :user, "rails"
set :use_sudo, false

set :mongrel_config, "/etc/mongrel_cluster/omdb.yml" 

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

if ENV['STAGE'] == 'live'
  set :gateway, "maggie.omdb.org"
  role :app, "homer.omdb.org"
  role :web, "homer.omdb.org"
  role :db,  "homer.omdb.org", :primary => true
  role :index, "homer.omdb.org"
else 
  # staging machine
  role :app, "maggie.omdb.org"
  role :web, "maggie.omdb.org"
  role :db,  "maggie.omdb.org", :primary => true
  role :index, "maggie.omdb.org"
end
# =============================================================================
# SSH OPTIONS
# =============================================================================
ssh_options[:keys] = %w( /var/www/localhost/rails/.ssh/id_rsa /home/benjamin/.ssh/id_dsa /home/jk/.ssh/id_dsa /Users/benjamin/.ssh/id_dsa )

after "deploy.symlink", "deploy.share"

# Start the normal deploy process, the tasks that'll get
# executed are:
# deploy -> update -> update_code -> symlink -> restart -> 
namespace :deploy do
  
  task :before_symlink do
    web.disable
    app.mongrel.stop
    app.ferret.stop
    
    # this needs to be run before symlinking,
    # as it will copy the current symlinks to the
    # new release. Important to remember, which 
    # ferret dir is the current active/online one.
    share.ferret
  end
  
  task :after_symlink do
    share.config
    share.image_cache
    share.sessions
    share.downloads
  end
  
  task :restart do
    app.mongrel.start
    app.ferret.start
    app.apache.restart
    web.enable
  end
  
  namespace :web do
    task :disable do
      run "svn up #{current_path}/public/maintenance.html"
    end
    
    task :enable do
      run "rm #{latest_release}/public/maintenance.html"
    end    
  end

  
end

namespace :setup do
  desc 'Setup the ferret infrastructure'
  task :ferret do
    { "ferret.index.production.0" => "ferret.index.production.online", 
      "ferret.index.production.1" => "ferret.index.production.offline",
      "ferret.index.production.last_switch" => "ferret.index.production.last_switch" }.each do |dir, link|
      run "ln -nfs #{deploy_to}/shared/db/#{dir} #{latest_release}/db/#{link}"
    end
  end
  
  desc 'Create all neccessary cache directories in the shared folder'
  task :cache_directories do
    [ 'public/image', 'tmp/sessions', 'public/downloads' ].each do |directory|
      run "mkdir -p #{deploy_to}/shared/#{directory}"
    end
  end
end

# Share content between releases, most obvious the sessions,
# the ferret-index and the image cache.
namespace :share do
  desc 'Install application configuration in the latest release'
  task :config do
    [ 'database.yml', 'backgroundrb.yml' ].each do |config_file|
      run "rm -f #{current_path}/config/#{config_file} && ln -nfs #{deploy_to}/shared/config/#{config_file} #{current_path}/config/#{config_file}"
    end
  end
  
  desc 'Move the ferret index symlinks and the switch status file to the new release'
  task :ferret do
    [ 'ferret.index.production.online', 'ferret.index.production.offline', 'ferret.index.production.last_switch' ].each do |file|
      run "mv #{current_path}/db/#{file} #{release_path}/db"
    end
  end
  
  desc 'Link to the shared image cache'
  task :image_cache do
    run "rm -rf #{current_path}/public/image && ln -nfs #{deploy_to}/shared/public/image #{current_path}/public/image"
  end
  
  desc 'Link to the shared session store'
  task :sessions do
    run "rm -rf #{current_path}/tmp/sessions && ln -nfs #{deploy_to}/shared/tmp/sessions #{current_path}/tmp/sessions"    
  end
  
  desc 'Link to the download directory'
  task :downloads do
    run "ln -nfs #{deploy_to}/shared/public/downloads #{current_path}/public/downloads"
  end
end

namespace :clear do
  desc 'Clears old sessions'
  task :sessions do
    run "cd #{current_path}; rake omdb:sessions:clear"
  end
  
  desc 'Clear image cache'
  task :image_cache do
    run "rm -rf #{deploy_to}/shared/public/image/*"
  end
end

# Application related tasks, like starting/stopping and restarting
# single applications.

namespace :app do
  namespace :mongrel do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the mongrel appserver"
      task t do
        sudo "mongrel_rails cluster::#{t.to_s} -C #{mongrel_config}"
      end
    end
  end
  
  namespace :apache do
    [ :stop, :start, :restart ].each do |t|
      desc "#{t.to_s.capitalize} the apache webserver"
      task t do
        sudo "/etc/init.d/apache2 #{t.to_s}"
      end
    end
  end
  
  namespace :ferret do
    desc 'Start the ferret indexing server'
    task :start do
      run "cd #{current_path}; nohup ./script/backgroundrb/start -e production -d > /dev/null 2>&1"
    end
    
    desc 'Stop the ferret indexing server'
    task :stop do
      run "#{deploy_to}/current/script/backgroundrb/stop"
    end
    
    desc 'Restart the ferret indexing server'
    task :restart do
      stop
      start
    end
  end  
end