#!/usr/bin/env bash

## 1. Place this script in the parent directory of your Meteor project
## 2. Run `sudo chmod 755 deploy_init.sh` to make it executable
## 3. Customize the values in the HARD-CODED section below to match
##    your project
## 4. Run `sudo ./deploy_init.sh` to set up the environment
## 5. When you are ready to deploy, run `meteor_deploy` as the user
##    referenced as `local_user`.

## << HARD-CODED
local_user=me      # name of a non-root user with an RSA key pair
remote_user=meteor # name of user who can ssh in to your server
ip=10.1.1.2        # IP address of server

project=barebones  # name of your Meteor project directory

url=http://www.example.com/     # address to visit from a browser
## HARD-CODED >>

repo=/var/www/$remote_user/bundle.git # path to the --bare repo on server


# COSMETICS 
orange='\033[0;33m'
yellow='\033[1;33m'
green='\033[0;32m'
lime='\033[1;32m'
grey='\033[0;37m'
white='\033[1;37m'
cyan='\033[1;36m'
blue='\033[1;34m'
plain='\033[0m' # No color, no weight


if ! [ $(id -u) = 0 ]; then

  echo
  echo -e "${blue}************ Checking if an id_rsa.pub file exists ************"

  path=/home/$local_user/.ssh
  list=$(ls -al $path | grep id_rsa)
  exists=$([ -z "$list" ] && echo 0  || echo 1)

  if [ $exists == 0 ]; then
    echo -e "${yellow}When deploying your app to the server, you will be logged in to"
    echo -e "this computer as '${orange}$local_user${yellow}'."
    echo 
    echo -e "You need to create an RSA key pair so that ${orange}$local_user${yellow} can push"
    echo -e "git files to the server as ${orange}$remote_user${yellow} without your needing to"
    echo    "enter a password."
    echo
    echo    "Run the commands in white below and follow the instructions:"
    echo
    echo -e "If you decide to use a passphrase when you create the key, make"
    echo    "sure that you will remember it, or that you keep it in a very"
    echo    "safe place, and that you remember where you have kept it."
    echo 
    echo -e "When you run ${white}ssh-copy-id $remote_user@$ip${yellow}, you will be asked for a"
    echo    "password. Use the temporary password that was set in the"
    echo -e "meteor_setup.sh script that you ran earlier on the remote server."
    echo
    echo -e "${white}su $local_user"
    echo    "ssh-keygen -t rsa"
    echo -e "${grey}<Follow the instructions>"
    echo -e "${white}ssh-copy-id $remote_user@$ip"
  else
    echo -e "${lime}It seems that you already have an RSA key pair. Use the"
    echo    "following command to copy the public key to the server at"
    echo    "$ip. You will be asked for a password. Use the temporary"
    echo    "password that was set in the meteor_setup.sh script that you"
    echo -e "ran earlier on the remote server.${white}"
    echo    ""
    echo -e "${white}su $local_user"
    echo    "ssh-copy-id $remote_user@$ip"    
  fi

  echo
  echo -e "${lime}Then check that you can log in to the server without entering a"
  echo -e "password and run ${white}exit${lime} to log out again:${plain}"
  echo
  echo -e "${white}ssh $remote_user@$ip"
  echo -e "${green}<Welcome message from server>"
  echo -e "${white}exit"
  echo
  echo -e "${lime}When you have done that, you can run this script again as root"
  echo -e "using ${white}sudo ./deploy_init${lime}.${plain}"
  echo

  exit 1
fi




## Uncomment the next three lines if git is not already installed
# echo "Ensuring that git is installed..."
# apt-get update
# apt-get install git





echo -e "${blue}1. Create script to push the bundle to the server"

#—————————————————————————————————————————————————————————————————————
cat << EOF > meteor_deploy
#!/usr/bin/env bash

if [ \$(id -u) == 0 ]; then
  echo "There is no need to run this script as root."
  echo "Run it as user whose RSA key has been uploaded to the server."
  echo "Please start again."
  exit
fi

timestamp=\`date '+%y%m%d-%H%M'\`

# Create a gzipped production-ready bundle
cd $project
meteor build --server-only ../deployment

# Extract it into deployment/current, replacing all existing content.
# This directory is managed by git. Files that have been altered will
# be detected by git.
cd ../deployment
rm -rf current/*
tar xf $project.tar.gz -C current/

# Archive the gzipped file for future reference
mv $project.tar.gz archive/\$project_\$timestamp.tar.gz

# Commit the changes and push to the remote repository
cd current
git add .
echo -e "${green}Changes:"
git commit -m "Deploy \$timestamp"
echo -e "${lime}Pushing to $ip...${plain}"
git push server master
echo -e "${lime}The update should now be visible at $url.${plain}"
EOF
#—————————————————————————————————————————————————————————————————————

chown $local_user:$local_user meteor_deploy
chmod 775 meteor_deploy





echo -e "${blue}2. Create directories to deal with deployment"

mkdir -p deployment/archive deployment/current/public deployment/current/tmp





echo -e "${blue}3. Initialize git in the deployment/current directory${plain}"
echo

cd deployment/current
git init

git remote add server ssh://$remote_user@$ip$repo
echo
echo -e "${cyan}Check that the remote repository details are correct:${white}"
git remote -v
cd ../ # deployment
chown -R $local_user:$local_user .
chmod -R 775 .
echo 
echo -e "${cyan}If not, delete the ${white}meteor_deploy${cyan} file, correct the details in the"
echo -e "HARD-CODED section of ${white}deploy_init.sh${cyan} and run ${white}sudo ./meteor_deploy${cyan}"
echo    "again."
echo
echo -e "When you are ready, run \`./meteor_deploy\` as $local_user.${plain}"
echo