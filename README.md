# MySQL Backup Script
BASH script that automatically creates backups on multiple MySQL databases tied to a single user and uploads the exports to an S3 bucket.

## Requirements
For this script to work as intended, you will need the following set up:
- **Server with Linux** installed as the operating system.  The following instructions work for a server running *Ubuntu 18.04 (Bionic Beaver)*.  Installation will likely be different on other operating systems and future versions.
- **SSH access** to the server, preferably using the SSH key handshake method.  For more information on installation, see https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804.
- **MySQL** installed and at least one database which will be the target for backup.  If you do not already have a database set up, follow the instructions at https://www.digitalocean.com/community/tutorials/how-to-install-the-latest-mysql-on-ubuntu-18-04.
- **AWS** hosting account with the following:
	- **IAM** user with the user credentials saved for use below.  If you do not already have an IAM user set up, follow the instructions at https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console
	- **S3** instance set up with a bucket for use below.  If you do not have an S3 bucket set up, follow the instructions at https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html.

## Installation

### Put the script on your server
Upload the `mysql-backup.sh` backup script to server, for example in a `~/__scripts/` directory.

First, SSH into the target server.  The below is for a generic user called *sshuser*.  You should replace with your specific values.  

See the **_Requirements_** section of this README if SSH is not already set up on your server.

```
ssh sshuser@yoursite.com
```
The commands below are to be made on command line in the server.

Download the file directly into the target directory using the WGET command and then change the permissions on the script to allow it to execute.

First, create the directory if it does not already exist.
```
mkdir ~/__scripts
```
Enter the directory to grab the backup script and change permissions to make it executable.
```
cd ~/__scripts &&
wget https://raw.githubusercontent.com/mlmedia/mysql-backup-script/master/mysql-backup.sh &&
chmod -R 755 ~/__scripts/mysql-backup.sh
```
### Install the AWS CLI
You should have your IAM credentials ready to use in the next step.  

If you do not already have an IAM user set up, see the **_Requirements_** section of this README.

```
sudo snap install aws-cli --classic &&
aws --version
```
Find and move bin to standard bin location:
```
sudo find / -name "aws" &&
sudo cp /snap/bin/aws /usr/local/bin
```

Test if cron will work with the script.
```
/bin/sh -c "(export PATH=/usr/bin:/bin:/usr/local/bin; ~/__scripts/mysql-backup.sh </dev/null)"
```

### Configure the AWS CLI
```
aws configure
```
When prompted, enter your AWS `Access Key ID` and `Secret Access Key` from your IAM user credentials.  You can hit return to accept the default (none) settings for `region name` and `output format`.

### Set config variables for the backup script
Set environment var for S3 bucket.  This presumes you have already set up a bucket under the S3 section in the above AWS account.  

If you do not already have an S3 bucket set up, see the **_Requirements_** section of this README.  

Create an S3DATABUCKET environment variable to the `/etc/environment` file so that it is accessible by cron.

```
sudo nano /etc/environment
```
Add the following line to the end of the file, using your S3 bucket name.
```
S3DATABUCKET=your-bucket-name
```

Log out and log in again.

```
exit
```

Set up mysql config creds.  The below presumes you have set up a mysql user called *mysqlsuperuser* that has permissions on all databases targeted for backup.  You can also use *root*, but this is safer.  

If you do not already have a database set up, see the **_Requirements_** section of this README.

```
mysql_config_editor set --login-path=local --host=localhost --user=mysqlsuperuser --password
```
Enter password for *mysqlsuperuser*.

### Test script
```
sh ~/__scripts/mysql-backup.sh
```
If the above backup database exports to a `~/__data` directory and successfully upload them to your S3 bucket, the next step is to simply setup a cronjob to automatically run the script on a schedule that works for you.

### Crontab setup
Set up crontab to automatically run according to appropriate frequency.

Make a logs directory if it doesn't already exist.
```
mkdir ~/logs
crontab -e
```
When the cron file opens, add a line for the script to run with appropriate frequency with proper logging.

```
MAILTO="you@yoursite.com"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SHELL=/bin/bash
0 4 * * 1 $HOME/__scripts/mysql-backup.sh > $HOME/logs/mysql-backup-$(date +\%m\%d).log 2>&1
```

For example, the above it to set the script to run once a week at 4am on Monday.  In addition, the output will be logged to a file and time stamped.  

In order to delete the old logs on a regular basis, add the following line to the crontab.  The following will automatically run every day at 6am and delete log files older than 25 days.

```
0 6 * * * find $HOME/logs/*.log -mtime +25 -exec rm -f {} \; > /dev/null 2>&1
```

### More testing
Check your `~/__data` and `~/logs` files and your S3 bucket for a few days to make sure it's working as expected.


### UPDATE: Fix for the SNAP_INSTANCE_NAME issue
Unexpectedly, the AWS CLI stopped syncing with a `SNAP_INSTANCE_NAME is not set` error logged.  The fix is to run the following commands to update the AWS CLI installation.

SSH into the server and run the following commands.  

```
sudo apt-get install -y python-pip &&
sudo pip install awscli boto boto3 --force-reinstall --upgrade &&
sudo pip install awscli --force-reinstall --upgrade &&
aws --version
```

Enter the password for `deploy`.
