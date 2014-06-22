#!/bin/bash
##############################################
# make-cdr.sh                                #
# This script connects to asterisk cdrdb     #
# then populates a csv file, reads from our  #
# pre-set headers file then emails the final #
# cdr report to a list of recipients         #
##############################################

# yay variables
DATE="$(date -d 'yesterday' +%Y-%m-%d)"
HOST="$(hostname)"
MYSQLUSER="cdr-read-only"
MYSQLPASS="notarealpassword"
ASTERISKDB="asteriskcdrdb"
SCRIPTDIR="/cdr-script"
WORKINGDIR="/tmp/cdr-script"
WORKINGCSV="raw-cdr.csv"
HEADERSCSV="/cdr-script/headers.csv"
FINALDIR="/cdr-script/cdrs"
FINALCSV="cdr-$HOST-$DATE.csv"

# ensure working directory exists
if [! -d $WORKINGDIR ]
  then
    mkdir -p $WORKINGDIR
fi

# ensure final directory existsi
if [! -d $FINALDIR ]
  then
    mkdir -p $FINALDIR
fi

# make sure there's not an existing CSV for today
# if there is for some reason move it and alert
if [ -a $WORKINGDIR/$WORKINGCSV ]
  then
    echo "$WORKINGDIR/$WORKINGCSV exists!"
    mv $WORKINGDIR/$WORKINGCSV $WORKINGDIR/$WORKINGCSV.bak
fi

# generate the raw cdr
mysql -u$MYSQLUSER -p$MYSQLPASS -D $ASTERISKDB -e "SELECT calldate,clid,src,dst,dcontext,channel,dstchannel,lastapp,lastdata,duration,billsec,disposition,amaflags,accountcode,uniqueid,userfield,did,recordingfile,cnum,cnam,outbound_cnum,outbound_cnam,dst_cnam FROM cdr WHERE calldate LIKE '$DATE%' INTO OUTFILE '$WORKINGDIR/$WORKINGCSV' FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n'"

# add our hostname to the end of the working CDR csv
#awk '{ print $0 "wilma" }' < $WORKINGDIR/$WORKINGCSV > $WORKINGDIR/$WORKINGCSV
sed -i "s/$/,$HOST/g" $WORKINGDIR/$WORKINGCSV

# make sure there's not an existing CSV for today
# if there is for some reason move it and alert
if [ -a $FINALDIR/$FINALCSV ]
  then
    echo "$FINALDIR/$FINALCSV exists!"
    mv $FINALDIR/$FINALCSV $FINALDIR/$FINALCSV.bak
fi

# cat the existing files to create one flat csv
# headers if they're needed if not can comment out
cat $HEADERSCSV > $FINALDIR/$FINALCSV
cat $WORKINGDIR/$WORKINGCSV >> $FINALDIR/$FINALCSV

# clean up working files
rm $WORKINGDIR/$WORKINGCSV

# change current commas into semicolons
sed -i "s/,/;/g" $FINALDIR/$FINALCSV

# change current pipes into comma's for CSV
sed -i "s/|/,/g" $FINALDIR/$FINALCSV

# change one last issue if it exists
sed -i "s/;$HOST/$HOST/g" $FINALDIR/$FINALCSV

while read email; do
  uuencode $FINALDIR/$FINALCSV $FINALCSV| mail -s "CDR $DATE for $HOST" $email
done < $SCRIPTDIR/emails.txt

