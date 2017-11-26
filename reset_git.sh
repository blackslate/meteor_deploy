#!/usr/bin/env bash

username=meteor

rm -rf /var/www/$username/bundle.git
mkdir -p /var/www/$username/bundle.git
cd /var/www/$username/bundle.git
git init --bare


cat << EOF > hooks/post-receive
#!/bin/sh

## /var/www/meteor/bundle.git/hooks/post-receive
echo -n "Executing hooks/post-receive as "; whoami

# Update the uninstalled raw directory on each new push
GIT_WORK_TREE=/var/www/$username/raw git checkout -f

# 1. Copy the current version of /var/www/meteor/raw/bundle to a tmp
#    directory
# 2. Call npm install --production so that tmp is ready for delivery
# 3. Archive the current directory at /var/www/meteor/bundle and
#    replace it with tmp. 
# 4. Restart nginx
# 
# NOTE: The file /etc/sudoers.d/deploy has been edited
# to give the meteor user root privileges for the deploy.sh
# script, and any commands that it executes inside this script.

cd /var/www/$username
sudo ./deploy.sh
echo "Deploy complete"
EOF


chmod 775 hooks/post-receive
chown -R $username:www-data /var/www/$username    