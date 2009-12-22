#!/bin/sh 
DEVELOPERS="omdb-svn@omdb-beta.org"
BUILDER="'OMDB Continuous Builder' <support@omdb-beta.org>"
BUILD_DIRECTORY=/home/rails/build
APP_NAME=OMDB
RAKE=/usr/bin/rake
cd $BUILD_DIRECTORY/omdb && \
  $RAKE -t test_latest_revision NAME="$APP_NAME" \
  RECIPIENTS="$DEVELOPERS" \
  SENDER="$BUILDER" &