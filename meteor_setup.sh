#!/usr/bin/env bash


## << HARD-CODED 
## Change these settings to suit your own project
username=meteor # Name of the user to create on the remote server.
                # All meteor activity will be handled by this user.
                # This user will have limited sudo rights for copying
                # and moving files.
                # The meteor web site will be installed at:
                #   /var/www/$username/bundle
                # The config file will be installed at:
                #   /etc/nginx/sites-available/$username.conf
password=meteor # password access should be removed after
                # installation and replaced with RSA key-based
                # authentication. A temporary password will do for now

# Used to configure Meteor site with nginx and Phusion Passenger
server_name="example.com www.example.com"
root_url=http://www.example.com
mongodb=exampledb
## HARD-CODED >>



# COSMETICS used to colour output in terminal
red='\033[1;31m'
blue='\033[1;34m'
cyan='\033[1;36m'
white='\033[1;37m'
yellow='\033[1;33m'
plain='\033[0m' # No color, no weight



# Warning only required if this script is run manually on the server
if [ $(id -u) != 0 ]; then
  echo
  echo -e "${cyan}You need to run this script as root. Please run:"
  echo -e "${white}sudo $0${plain}"
  echo
  exit 1
fi


echo
echo -e "${yellow}NOTE: In the output below, you can safely ignore lines in red that say"
echo -e "${red}==> default: dpkg-preconfigure: unable to re-open stdin: No such file or directory"
echo -e "${yellow}See:"
echo
echo -e "${white}https://www.ikusalic.com/blog/2013/10/03/vagrant-intro/"
echo -e "${white}http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory"
echo
echo -e "${yellow}Other output in red should all be simple feedback, rather than errors.${plain}"
echo



echo -e "${blue}1. Create meteor user with limited sudo access"

password=$(perl -e 'print crypt($ARGV[0], "wQ")' $password)
useradd -m -p $password $username

# Editing files in /etc/sudoers.d/ should be done with visudo as root,
# to ensure that there are no errors which could lock you out of sudo
# access. If there are any problems, you can use
# `pkexec visudo -f /etc/sudoers.d/deploy` to edit this file, even
# if sudo access is unavailable.
# 
# https://askubuntu.com/questions/73864/how-to-modify-an-invalid-etc-sudoers-file
# 
# However, since this script is run on a clean installation, there
# should be no conflicts with other files in /etc/sudoers.d/, so it's
# safe to proceed.

#—————————————————————————————————————————————————————————————————————
cat << EOF > /etc/sudoers.d/deploy
User_Alias METEOR=$username
Cmnd_Alias DEPLOY=/bin/mkdir,/bin/cp,/bin/mv,/bin/chown,/bin/ls,/var/www/$username/deploy.sh

#user  terminal  acting as  option     can run this command with sudo:
METEOR ALL=      (root)     NOPASSWD:  DEPLOY
EOF
#—————————————————————————————————————————————————————————————————————

chmod 0440 /etc/sudoers.d/deploy

# Check that the configuration is valid. The following command should
# output these lines in the terminal window. (The second line will
# appear only if this is run as a Vagrant provisioning script.)
# 
# ==> default: /etc/sudoers: parsed OK
# ==> default: /etc/sudoers.d/90-cloud-init-users: parsed OK
# ==> default: /etc/sudoers.d/README: parsed OK
# ==> default: /etc/sudoers.d/deploy: parsed OK

visudo -c





echo -e "${blue}2. Ensure the system is up-to-date"

apt-get -y update
apt-get -y upgrade





echo -e "${blue}3. Install curl and git, plus tree for feedback"

apt-get install -y curl
apt-get install git
apt install tree





echo -e "${blue}4. Install Node Version Manager (nvm)"

export NVM_DIR="/home/$username/.nvm"

sudo -u $username -H bash << EOF
echo "————————————————————————————————————————————————————————————————"
echo -n "Installing nvm as..."; whoami

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo
echo -e "${blue}4. Installing Node.js v8.8.1 and npm 5.4.2${cyan}"
echo -e "${cyan}This outputs a lot of ugly progress bar updates in the terminal window."
echo -e "${cyan}To hide this, all errors for the next operation will be sent to /dev/null."
echo -e "${cyan}However, if there is an error, it won't be shown."
echo -e "${cyan}If you want to see all output to stderr for this command, delete"
echo -e "${white}2>/dev/null${cyan} from line 121: ${white}nvm install v8.8 2>/dev/null
${plain}"
nvm install v8.8 2>/dev/null

echo -e "${blue}5. Check that node 8.8.1 and npm 5.4.2 are installed${plain}"
echo "which node && node -v"
which node
node -v
echo "which npm && npm -v"
which npm
npm -v
echo "————————————————————————————————————————————————————————————————"
EOF

echo -n "$0 running as..."; whoami

echo -e "${blue}6. Create symlinks for node and npm at /usr/bin/"

ln -s /home/$username/.nvm/versions/node/v8.8.1/bin/node /usr/bin/
ln -s /home/$username/.nvm/versions/node/v8.8.1/bin/npm /usr/bin/
echo "Checking symlinks..."
echo -n "/usr/bin/node -> "; readlink -f /usr/bin/node
echo -n "/usr/bin/npm -> "; readlink -f /usr/bin/npm





echo -e "${blue}7. Install nginx"

apt-get -y install nginx
service nginx start
echo
echo "nginx -t"
nginx -t
echo "service nginx status"
service nginx status





echo -e "${blue}8. Install Phusion Passenger"

apt-get install -y dirmngr gnupg
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
apt-get install -y apt-transport-https ca-certificates
sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
apt-get update
apt-get install -y nginx-extras passenger

# Clean up: remove nginx-core which is no longer needed
apt-get -y autoremove





echo -e "${blue}9. Enable Passenger with nginx"

if [ ! -f /etc/nginx/nginx.conf.factory_default ]
then
  cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.factory_default
  sed -i -e "s^# include /etc/nginx/passenger.conf;^include /etc/nginx/passenger.conf;^" /etc/nginx/nginx.conf
fi
service nginx restart

echo "service nginx status"
service nginx status





echo -e "${blue}10. Install MongoDB"

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/testing multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get update
apt-get install -y mongodb-org
service mongod start
echo
echo "service mongod status:"
service mongod status





echo -e "${blue}11. Enable ufw firewall"

ufw allow 22 && ufw allow http && ufw allow https && ufw --force enable
echo "ufw status"
ufw status





echo -e "${blue}12. Create site directory for meteor app"

cd /var/www/
mkdir -p $username/bundle





echo -e "${blue}13. Configure nginx with Phusion Passenger for meteor app"

#—————————————————————————————————————————————————————————————————————
cat << EOF > /etc/nginx/sites-available/$username.conf
server {
  listen 80;
  listen [::]:80;

  # Tell Nginx and Passenger where the app's 'public' directory is
  root /var/www/$username/bundle/public;

  server_name $server_name;

  ## ADDED FOR PASSENGER
  # Turn on Passenger
  passenger_enabled on;
  # Tell Passenger that your app is a Meteor app
  passenger_app_type node;
  passenger_startup_file main.js;

  # Tell your app where MongoDB is
  passenger_env_var MONGO_URL mongodb://localhost:27017/$mongodb;
  # Tell your app what its root URL is
  passenger_env_var ROOT_URL $root_url;
}
EOF
#—————————————————————————————————————————————————————————————————————




echo -e "${blue}14. Enable the site"

ln -s /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/
echo "ls -al /etc/nginx/sites-enabled/*"
ls -al /etc/nginx/sites-enabled/*
service nginx restart

echo
echo "nginx -t"
nginx -t
echo
echo "service nginx status"
service nginx status





echo -e "${blue}15. Create Git hooks/post-receive"

# The output of hooks/post-receive will be shown in the terminal
# window on the client where you call `./meteor_deploy`

mkdir -p /var/www/$username/bundle.git
cd /var/www/$username/bundle.git
git init --bare

#—————————————————————————————————————————————————————————————————————
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
#—————————————————————————————————————————————————————————————————————

chmod 775 hooks/post-receive





echo -e "${blue}16 Create deploy.sh"
cd /var/www/$username
pwd


#—————————————————————————————————————————————————————————————————————
cat << EOF > deploy.sh
#!/bin/sh

echo -n "Executing deploy.sh as "; whoami
echo

# Create a new copy of raw, and add a file containing creation date
# The contents of the date file will used as the name of the directory
# to which this version of the app will be archived when a new version
# is pushed to the server.

cp -r raw/bundle tmp
DATE=\`date '+%y%m%d-%H%M'\`
echo \$DATE > tmp/date

chown -R $username tmp

# Run npm install
cd tmp/programs/server

# - - - - - - - - - - - - - - - - - - - - - - - - -
sudo -u $username -H bash -l << HERE
echo -n "Running npm install --production in "; pwd
echo -n "as "; whoami
echo
npm install --production
HERE
# - - - - - - - - - - - - - - - - - - - - - - - - -

# Take ownership
cd - # prints the current directory in the terminal
chown -R $username:www-data tmp

# Archive the current version and replace it with the new one
DATE=\`cat bundle/date\`
mv bundle archive/\$DATE
mv tmp bundle

tree -L 2

service nginx restart

echo
echo "nginx -t"
nginx -t
echo
echo "service nginx status"
service nginx status
EOF
#—————————————————————————————————————————————————————————————————————

chmod 775 deploy.sh





echo -e "${blue}17. Create a dummy raw/ directory to be replaced by the first push"

mkdir -p /var/www/$username/raw/public/server

#—————————————————————————————————————————————————————————————————————
cat << EOF > /var/www/$username/raw/package.json
{
  "name": "placeholder"
, "description": "Description goes here"
, "repository": {
   "type": "git"
  , "url": "https://github.com/gitusername/placeholder.git"
  }
, "license": "AAL"
}
EOF
#—————————————————————————————————————————————————————————————————————

#—————————————————————————————————————————————————————————————————————
cat << EOF > /var/www/$username/raw/README.md
Just another ReadMe file
EOF
#—————————————————————————————————————————————————————————————————————

chown -R $username:www-data /var/www/$username

echo "tree /var/www"
tree /var/www





echo -e "${cyan}"
echo -e "${cyan}The server is now ready for you to deploy your Meteor app."
echo    "On your development machine, you can now run the deploy_init.sh script"
echo -e "in the parent folder of your Meteor app.${white}"
echo    ""
echo -e "${white}cd /path/to/meteor_app/.."
echo    "cp /path/to/deploy_init.sh ."
echo    "sudo chmod 755 deploy_init.sh"
echo    "sudo ./deploy_init.sh"
echo    ""