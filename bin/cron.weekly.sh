#!/bin/sh
DIR_NAME=`dirname $0`

cd ${DIR_NAME}
cd ..

export RAILS_ENV=production

# Store Popularity History
rake stats_calc RAILS_ENV=production

# Clean old session
nice rake omdb:sessions:clear

