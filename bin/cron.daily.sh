#!/bin/sh
DIR_NAME=`dirname $0`

cd ${DIR_NAME}
export RAILS_ENV=production

# reindex almost everything
rake omdb:update_index_daily

# Calculate Popularity (requires an Apache-CustomLog)
# see apache.conf in config/webserver
cd ..
./script/runner "CalculatePopularities.calculate"

# Select the movie of the day
rake select_movie_of_the_day
# Select the person of the day
rake select_person_of_the_day

rake omdb:generate_people_csv
rake omdb:export_plot_keywords
rake omdb:export_place_keywords
rake omdb:export_time_keywords
rake omdb:export_emotion_keywords
rake omdb:export_audieces
rake omdb:export_movies

# generate a google sitemap
./bin/sitemap_gen.py --config=config/sitemap_config.xml

# restart mongrel to avoid memory leaks
./bin/restartMongrel.sh

# and finally, backup the database
./bin/dailyBackup.sh

# remove old cached files
rm -rf ./public/anonymous/en
rm -rf ./public/anonymous/de
rm -rf ./public/logged_in/en
rm -rf ./public/logged_in/de

