#!/bin/sh
#
svn up ~/current/public
cd ~/current
sudo /etc/init.d/mongrel_cluster restart
sudo /etc/init.d/apache2 restart
./script/backgroundrb/stop
./script/backgroundrb/start -d -e production
rm ~/current/public/maintenance.html
