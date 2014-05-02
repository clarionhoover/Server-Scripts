#!/bin/bash

#################################################
# backup.sh                                     #
# Author: Randy Hoover <randy.hoover#gmail.com> #
# Purpose: To back up the webroot and the mysql #
# databases on my server and create compressed  #
# tarballs for archival                         #
#################################################

WEBROOT="/webroot"
LOCALSTORE="/backups"
DATE="$(date +%Y-%m-%d)"
MYSQLUSER="backup"
MYSQLPASSWORD=`cat /root/.mysqlbackuppw`

# start with the files
echo "$(date +"%D %r") - Beginning webroot tarball"
tar -czf $LOCALSTORE/webroot-backups_$DATE.tar.gz $WEBROOT && echo "$(date +"%D %r") - webroot tarball complete" || echo "$(date +"%D %r") - webroot tarball failed" 
# finished files

# now to the database
for i in $(echo 'SHOW DATABASES;' | mysql -u $MYSQLUSER -p$MYSQLPASSWORD | grep -v '^Database$' | grep -v 'information_schema')
do
	echo "$(date +"%D %r") - beginning dump of $i"
	mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD $i > $LOCALSTORE/$i.$DATE.sql && echo "$(date +"%D %r") - finished dump of $i" || echo "$(date +"%D %r") - dump of $i failed"
done
# finished dumping sql files

# time to tar up the sql files
tar -czf $LOCALSTORE/mysql-backups_$DATE.tar.gz $LOCALSTORE/*.$DATE.sql && echo "$(date +"%D %r") - sql tarball complete" || echo "$(date +"%D %r") - sql tarball failed"
# tarred

# time to tar the web backups and sql
tar -czf $LOCALSTORE/backup_$DATE.tar.gz $LOCALSTORE/webroot-backups_$DATE.tar.gz $LOCALSTORE/mysql-backups_$DATE.tar.gz && echo "$(date +"%D %r") - full tarbll complete" || echo "$(date +"%D %r") - full tarball failed"

# time to clean up
rm -f $LOCALSTORE/*.$DATE.sql
rm -f $LOCALSTORE/*-backups_$DATE.tar.gz

echo "$(date +"%D %r") - Backup Complete!"
# Done!
