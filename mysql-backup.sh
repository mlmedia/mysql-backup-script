#!/bin/bash

# config variables
HOME="/home/deploy";
NOWDATE=$(date +"%Y%m%d");
NOWDAY=$(date +"%d");
BACKUPDIR="__data";
MYSQL="$(which mysql)";
MYSQLDUMP="$(which mysqldump)";

# generate the SITENAME for the AWS directory from the formatted host
# - lowercase with hyphens only
HOSTNAME="$(hostname -f)";
SITENAME=`echo ${HOSTNAME} | tr [:upper:] [:lower:] | tr -c '[:alnum:]' '-' | tr ' ' '-' | tr -s '-'| sed 's/\-*$//'`;

# check to see if target path exists
# if so, delete the old one and create a new one
# otherwise just create it
TARGETPATH=$HOME/$BACKUPDIR/$NOWDAY;
if [ -d $TARGETPATH ]
then
	rm -r $TARGETPATH;
	mkdir -p $TARGETPATH;
else
	mkdir -p $TARGETPATH;
fi

# automatically backup each database using the hostname
DBS="$($MYSQL --login-path=local -Bse 'show databases')";
for DBNAME in $DBS
do
	# skip the system databases
	if [ "$DBNAME" != "performance_schema" ] &&
	[ "$DBNAME" != "mysql" ] &&
	[ "$DBNAME" != "information_schema" ] &&
	[ "$DBNAME" != "sys" ]
	then
		# dump the data into a SQL file inside the target path
		$MYSQLDUMP --login-path=local -e  $DBNAME | gzip > $TARGETPATH/${DBNAME}-$NOWDATE.sql.gz;
		printf "$DBNAME backed up to $TARGETPATH\n";
	fi
done

# sync with Amazon S3 using the CLI (with server side encryption)
# install AWS CLI with instructions found here: https://linuxconfig.org/install-aws-cli-on-ubuntu-18-04-bionic-beaver-linux
# check for existence of environment variable
if [ -z "$S3BUCKET" ]
then
	echo "You need to set an ENVIRONMENT variable for the target S3BUCKET (e.g. export S3BUCKET=my-bucket-name)"
else
	aws s3 sync $HOME/__data s3://$S3BUCKET/$SITENAME --delete --sse;
fi
