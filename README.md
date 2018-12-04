# MySQL Backup Script
BASH script that automatically creates backups and uploads to and S3 bucket

## Requirements
For this script to work as intended, you will need the following set up:
- server with Linux installed as the operating system
- AWS hosting account
- AWS IAM user
- AWS S3 account

## Installation
The installation instructions below work for a server running Ubuntu 18.04 (Bionic Beaver).  Installation will likely be different on other operating systems and future versions.

### Upload
Upload the `mysql-backup.sh` backup script to server, for example in a `/root/__scripts/` directory.

- SSH into the target server.
```bash
ssh root@yoursite.com
```
The following commands are to be made on command line in the server.

- Change the permissions on the script to group execute.
```bash
chmod -R 755 /root/__scripts/mysql-backup.sh
```
- Install the AWS CLI.
```bash
sudo snap install aws-cli --classic && aws --version
```
- Find and move bin to standard bin location.
```bash
sudo find / -name "aws" && sudo cp /snap/bin/aws /usr/local/bin
```

- Test if cron will work with script.
```bash
/bin/sh -c "(export PATH=/usr/bin:/bin:/usr/local/bin; /root/__scripts/mysql-backup.sh </dev/null)"
```

- Get and save AWS CLI access credentials from IAM user in safe place.
```bash
aws configure
- (enter AWS Access Key ID)
- (enter AWS Secret Access Key)
- (press return for default (none) region name)
- (press return for default (none) output format)
```

- Set environment var for S3 bucket.  This presumes you have already set up a bucket under the S3 section in the above AWS account.
```bash
export S3BUCKET=your-bucket-name
```

- Set up mysql config creds.  The below presumes you have set up a mysql user that has permissions on all databases targeted for backup.
```bash
mysql_config_editor set --login-path=local --host=localhost --user=mysqlsuperuser --password
```

- Enter password for `mysqlsuper`.

- Test mysql backup script.
```bash
sh /root/__scripts/mysql-backup.sh
```
