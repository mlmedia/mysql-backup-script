# MySQL Backup Script
BASH script that automatically creates backups and uploads to and S3 bucket

## Requirements
For this script to work as intended, you will need the following set up:
	- server with Linux installed as the operating system
	- AWS hosting account
	- AWS IAM user
	- AWS S3 account

## Installation
1. (upload the `mysql-backup.sh` backup script to server, for example in a `/root/__scripts/` directory)
2. (ssh into target server):
	- (e.g.) `ssh root@yoursite.com`
3. (change the permissions on the script to group execute):
	- `chmod -R 755 /root/__scripts/mysql-backup.sh`
4. (install aws cli):
	- `sudo snap install aws-cli --classic && aws --version`
	- (find and move bin to standard bin location):
		- `sudo find / -name "aws"`
		- (copy bin executable to `/usr/local/bin`)
		- `sudo cp /snap/bin/aws /usr/local/bin`
		- (test if cron will work with script):
			- `/bin/sh -c "(export PATH=/usr/bin:/bin:/usr/local/bin; /root/__scripts/mysql-backup.sh </dev/null)"`
	- (get and save AWS CLI access credentials from IAM user in safe place)
	- `aws configure`
	- (enter AWS Access Key ID)
	- (enter AWS Secret Access Key)
	- (press return for default (none) region name)
	- (press return for default (none) output format)
5. (set environment var for S3 bucket):
	- `export S3BUCKET=your-bucket-name`
		- (e.g.) `export S3BUCKET=mlmedia-app-data`
6. (set up mysql config creds):
	- `mysql_config_editor set --login-path=local --host=localhost --user=mysqlsuperuser --password`
	- (enter password for mysqlsuper)
7. (test mysql backup script):
	- `sh /root/__scripts/mysql-backup.sh`
