#!/bin/sh
DIR_NAME=`dirname $0`

cd ${DIR_NAME}
export RAILS_ENV=production

# reindex jobs and categories
rake omdb:update_index

