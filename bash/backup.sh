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
MYSQLUSER="backup"
MYSQLPASSWORD=`cat /root/.mysqlbackuppw`
REMOTEHOST="fs1.codefi.re"
REMOTEUSER="anthrax"
REMOTEDIRECTORY="/home/anthrax/storage/backups"
YEAR="$(date +%Y)"
MONTH="$(date +%m)"
DAY="$(date +%d)"
DATE="$YEAR-$MONTH-$DAY"


# start with the files
echo "$(date +"%D %r") - Beginning webroot tarball"
tar -czPf $LOCALSTORE/webroot-backups_$DATE.tar.gz $WEBROOT && echo "$(date +"%D %r") - webroot tarball complete" || echo "$(date +"%D %r") - webroot tarball failed" 
# finished files

# now to the database
for i in $(echo 'SHOW DATABASES;' | mysql -u $MYSQLUSER -p$MYSQLPASSWORD | grep -v '^Database$' | grep -v 'information_schema')
do
	echo "$(date +"%D %r") - beginning dump of $i"
	mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD $i > $LOCALSTORE/$i.$DATE.sql && echo "$(date +"%D %r") - finished dump of $i" || echo "$(date +"%D %r") - dump of $i failed"
done
# finished dumping sql files

# time to tar up the sql files
tar -czPf $LOCALSTORE/mysql-backups_$DATE.tar.gz $LOCALSTORE/*.$DATE.sql && echo "$(date +"%D %r") - sql tarball complete" || echo "$(date +"%D %r") - sql tarball failed"
# tarred

# time to tar the web backups and sql
tar -czPf $LOCALSTORE/backup_$DATE.tar.gz $LOCALSTORE/webroot-backups_$DATE.tar.gz $LOCALSTORE/mysql-backups_$DATE.tar.gz && echo "$(date +"%D %r") - full tarbll complete" || echo "$(date +"%D %r") - full tarball failed"

# time to clean up
rm -f $LOCALSTORE/*.$DATE.sql
rm -f $LOCALSTORE/*-backups_$DATE.tar.gz

echo "$(date +"%D %r") - Local clean up Complete!"

# Time to copy onto redundant storage on another host
# first we need to do some testing to see if the folders we need exist
# first the year
echo "$(date +"%D %r") - Creating Remote Backup Directory"
if (ssh $REMOTEUSER@$REMOTEHOST "! [ -d $REMOTEDIRECTORY/$YEAR ]"); then
	ssh $REMOTEUSER@$REMOTEHOST "mkdir $REMOTEDIRECTORY/$YEAR"
	echo "$(date +"%D %r") - Created $REMOTEDIRECTORY/$YEAR directory on remote host"
fi
if (ssh $REMOTEUSER@$REMOTEHOST "! [ -d $REMOTEDIRECTORY/$YEAR/$MONTH ]"); then
        ssh $REMOTEUSER@$REMOTEHOST "mkdir $REMOTEDIRECTORY/$YEAR/$MONTH"
        echo "$(date +"%D %r") - Created $REMOTEDIRECTORY/$YEAR/$MONTH directory on remote host"
fi
if (ssh $REMOTEUSER@$REMOTEHOST "! [ -d $REMOTEDIRECTORY/$YEAR/$MONTH/$DAY ]"); then
        ssh $REMOTEUSER@$REMOTEHOST "mkdir $REMOTEDIRECTORY/$YEAR/$MONTH/$DAY"
        echo "$(date +"%D %r") - Created $REMOTEDIRECTORY/$YEAR/$MONTH/$DAY directory on remote host"
fi
echo "$(date +"%D %r") - Remote Backup Directory Created"

echo "$(date +"%D %r") - Begin rsync of backup to remote host"
rsync -azh $LOCALSTORE/backup_$DATE.tar.gz $REMOTEUSER@$REMOTEHOST:$REMOTEDIRECTORY/$YEAR/$MONTH/$DAY/ && echo "$(date +"%D %r") - rsync completed sucessfuly" || echo "$(date +"%D %r") - rsync failed"

echo "$(date +"%D %r") - Backup Complete!"
