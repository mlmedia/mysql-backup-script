# MySQL Backup Script
BASH script that automatically creates backups and uploads to an S3 bucket.

## Requirements
For this script to work as intended, you will need the following set up:
- Server with Linux installed as the operating system
- AWS hosting account
- AWS IAM user
- AWS S3 account

## Installation
The installation instructions below work for a server running Ubuntu 18.04 (Bionic Beaver).  Installation will likely be different on other operating systems and future versions.

### Put the script on your server
Upload the `mysql-backup.sh` backup script to server, for example in a `/root/__scripts/` directory.

- SSH into the target server.
```bash
ssh root@yoursite.com
```
The following commands are to be made on command line in the server.

Change the permissions on the script to group execute:
```bash
chmod -R 755 /root/__scripts/mysql-backup.sh
```
### Install the AWS CLI
```bash
sudo snap install aws-cli --classic && aws --version
```
Find and move bin to standard bin location:
```bash
sudo find / -name "aws" && sudo cp /snap/bin/aws /usr/local/bin
```

### Test cron
Test if cron will work with script.
```bash
/bin/sh -c "(export PATH=/usr/bin:/bin:/usr/local/bin; /root/__scripts/mysql-backup.sh </dev/null)"
```

### Configure AWS
Get and save AWS CLI access credentials from IAM user in safe place.
```bash
aws configure
- (enter AWS Access Key ID)
- (enter AWS Secret Access Key)
- (press return for default (none) region name)
- (press return for default (none) output format)
```

### Set config variables for the backup script
Set environment var for S3 bucket.  This presumes you have already set up a bucket under the S3 section in the above AWS account.
```bash
export S3BUCKET=your-bucket-name
```

Set up mysql config creds.  The below presumes you have set up a mysql user called `mysqlsuperuser` that has permissions on all databases targeted for backup.  You can also use `root`, but this is safer.
```bash
mysql_config_editor set --login-path=local --host=localhost --user=mysqlsuperuser --password
```
Enter password for `mysqlsuperuser`.

### Test script
```bash
sh /root/__scripts/mysql-backup.sh
```
If the above backup database exports to a `/root/__data` directory and successfully upload them to your S3 bucket, the next step is to simply setup a cronjob to automatically run the script on a schedule that works for you.

### Crontab setup
Set up crontab to automatically run according to appropriate frequency.

Make a logs directory if it doesn't already exist.
```bash
mkdir /root/logs
crontab -e
```
When the cron file opens, add a line for the script to run with appropriate frequency with proper logging.

```bash
MAILTO="you@yoursite.com"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SHELL=/bin/bash
0 4 * * 1 /root/__scripts/mysql-backup.sh > /root/logs/mysql-backup-$(date +\%m\%d).log 2>&1
```

For example, the above it to set the script to run once a week at 4am on Monday.  In addition, the output will be logged to a file and time stamped.  

In order to delete the old logs on a regular basis add the following line to the crontab, which will automatically run every day at 5am and delete log files older than 25 days.

```bash
0 5 * * * find $HOME/logs/*.log -mtime +25 -exec rm -f {} \; > /dev/null 2>&1
```

### More testing
Check your `/root/__data` and `/root/logs` files for a few days to make sure it's working as expected.  
