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
		# format the db name to use dash for underscores and other special chars
		CLEANNAME=`echo ${DBNAME} | tr [:upper:] [:lower:] | tr -c '[:alnum:]' '-' | tr ' ' '-' | tr -s '-'| sed 's/\-*$//'`;
		# dump the data into a SQL file inside the target path
		$MYSQLDUMP --login-path=local -e $DBNAME | gzip > $TARGETPATH/${CLEANNAME}-$NOWDATE.sql.gz;
		printf "$DBNAME backed up to $TARGETPATH\n";
	fi
done

# sync with Amazon S3 using the CLI (with server side encryption)
# install AWS CLI with instructions found here: https://linuxconfig.org/install-aws-cli-on-ubuntu-18-04-bionic-beaver-linux
# check for existence of environment variable
if [ -z "$S3DATABUCKET" ]
then
	echo "You need to set an ENVIRONMENT variable for the target S3DATABUCKET (e.g. export S3DATABUCKET=my-bucket-name)";
else
	echo "Synching data to AWS";
	aws s3 sync $HOME/__data s3://$S3DATABUCKET/$SITENAME --delete --sse;
fi
