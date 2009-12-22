#!/bin/bash

. /etc/profile

BACKUPDIR=/var/backup/mysql/omdb_prod/
DOWNLOADFILE=/var/www/www.omdb.org/rails/shared/public/downloads/omdb_prod.dump.sql.bz2
TMPDIR=/var/tmp
TMPBACKUPFILE="${TMPDIR}/backup-mysql.`date +%a`.sql"
LOGFILE=/var/log/rails/backup.log

echo "Log started on `date`" >$LOGFILE

mysqldump -u rails --password="rails" omdb_prod >$TMPBACKUPFILE 2>>$LOGFILE
nice bzip2 ${TMPBACKUPFILE}

curl -s -T "${TMPBACKUPFILE}.bz2" ftp://omdb-backup:RmsC9XiaWbsx@php1.extern.moviepilot.de/

mv ${TMPBACKUPFILE}.bz2 ${BACKUPDIR}
echo "Log ended on `date`" >>$LOGFILE

# Create the downloadable version of the database.
#mysqldump omdb_prod --ignore-table=omdb_prod.users --ignore-table=omdb_prod.log_entries --add-drop-table --create-options --user=rails --password=rails > ${TMPBACKUPFILE}
#mysqldump --no-data --user=rails --password=rails omdb_prod users log_entries >> ${TMPBACKUPFILE}
#nice bzip2 ${TMPBACKUPFILE}
#mv ${TMPBACKUPFILE}.bz2 /dev/null
