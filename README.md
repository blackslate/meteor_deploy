# meteor_deploy

Deploying a Meteor app to your own server requires a number of fiddly steps. This repository contains two scripts that can reduce the task to a single command:

`meteor_deploy`

To try this at home, you want to have:

* A Meteor app
* A local computer to work on (your client machine)
* A  server
* An RSA key pair that allows you to connect to the server without entering a password

Below, you will be able to walk through this, step by step. This repository contains everything that you might need to get started.

#### Meteor App
This tutorial assumes that you already have [Meteor](https://www.meteor.com/) installed, and that you know how to create a barebones Meteor app with a Click Me button, by running `meteor create`. That's the app that you can use to check that everything is working correctly ,
####<a name="server">Server
You'll need a server set up to deliver a Meteor app. This means that it should have the correct versions of the following software packages installed on it:

* Node.js  
* npm  
* MongoDB  
* nginx  
* Phusion Passenger
* Git

It will also need to have:

* A non-root user with certain sudo permissions
* Certain nginx configuration files set up correctly
* A specific file arrangement in `/var/www/`
* A bare Git repository

But you don't need to worry about any of this: this tutorial explains how to use a bash script to install all these packages and set up everything automatically. All you will need to do is change about half a dozen lines at the beginning of a couple of scripts, to customize them for you own project.

#### Virtual machine
Your server can be another computer on the same network, a remote server that you can connect to over the interet, or a virtual machine running on your local computer.

For simplicity, this tutorial explains how to set up a virtual machine as your server. [VirtualBox](https://www.virtualbox.org/) is a free and open-source product that allows you to simulate a remote server inside your local computer.

 If you are working with a virtual machine, it helps to use [Vagrant](https://www.vagrantup.com/) to set it up. Vagrant is an open-source software product that helps you to set up and manage any number of virtual machines. Vagrant is not essential for running a virtual machine, but it can save you time by taking care of many housekeeping steps for you.

There are products other than VirtualBox that you can use to simulate a server, and Vagrant works with many of these. Meteor apps can run on a wide number of operating systems. 

The scripts have been tested with Vagrant 1.9.7 and VirtualBox 5.0.40 set up to run with Ubuntu 16.03.3 LTS. They have been designed for use on a freshly installed server, where no other packages have yet been installed. If you already have a web site in place, or any of the packages listed at in the [Server](#server) section above, then you may need to edit the scripts manually and proceed with caution.

## Local Installations
Below are the steps if you are starting from scratch. You'll need to:

* Install VirtualBox
* Install Vagrant
* Set up Vagrant to install an operating system on the virtual machine

If you already have a freshly installed server available, you can skip to [Setting up the server](#setup)

###1 Install VirtualBox:

In a Terminal window:

``` bash
$ sudo apt-get update
$ sudo apt-get install virtualbox
```
Check that it is installed:

``` bash
$ vboxmanage -v
5.0.40_Ubuntur115130
```
Launch VirtualBox 

``` bash
$ virtualbox
```
####1.1 Create a Host-only Network 

In the VirtualBox user interface, select the menu item File > Preferences. In the dialogue window that opens, select Network in the left-hand pane and then click on the tab Host-only Networks. Click on the [+] button to create a new network. It will probably be called something like `vboxnet0`.

Set the IPv4 address to `10.1.1.1` with  Mask of `255.255.255.0`

This will add a new IP address of  `10.1.1.1` to your work machine, so that it will be able to connect to a simulated network. In a moment, you'll set up a virtual server that you can connect to at `10.1.1.2`, as if it were elsewhere in the world.

###2 Install Vagrant
In a Terminal window:

``` bash
$ sudo apt-get update
$ sudo apt-get install vagrant
```
Check that it is correctly installed

``` bash
$ vagrant --version
1.9.7
```
Installing Vagrant will create a hidden folder at the root of your home directory. You can get an glimpse of what has been installed if you use the `tree` command. What you see may be different from what is shown below.

``` bash
apt get tree
... <skipping some installation stuff>
tree ~/.vagrant.d -L 2
/home/me/.vagrant.d
├── boxes
│   └── ubuntu-VAGRANTSLASH-xenial64
├── data
│   ├── checkpoint_cache
│   ├── checkpoint_signature
│   ├── fp-leases
│   └── machine-index
├── gems
│   ├── 2.3.4
│   └── ruby
├── insecure_private_key
├── rgloader
│   └── loader.rb
├── setup_version
└── tmp
    ├── boxe885b0712a7ffc43067c38045003ddab96e9af85
    └── vagrant-package-20170828-18991-137k1t3
```


###3 Set up a virtual machine
1. Prepare a directory for the installation

``` bash
$ mkdir DeployTest
$ cd DeployTest
$ vagrant init "ubuntu/xenial64"
```
This will create a hidden `.vagrant` folder inside the chosen directory, and will add a file called `Vagrantfile` which consists mostly of explanatory comments for features that are not needed in this tutorial. You can replace the contents of `Vagrantfile` with this:

*Vagrantfile*

``` ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  
  config.vm.box = "ubuntu/xenial64"

  config.vm.network "private_network", ip: "10.1.1.12"

  config.vm.provision :shell, :path => "meteor_setup.sh"

end
```
To create your virtual server, you can now simply execute the following in your Terminal window (but don't do this yet ... the `meteor_setup.sh` script is not yet in place.

``` bash
$ vagrant up
```

The contents of the `Vagrantfile` will make Vagrant do three things:
* Download a directory to `/.vagrant /boxes/ubuntu-VAGRANTSLASH-xenial64 containing all the information needed to install Ubuntu 16.04 on the virtual server
* Set up the virtual server so that it has the address `10.1.1.2 `
* Upload the script named `meteor_setup.sh` to the server, and execute it as `root`.

You can find the `meteor_setup.sh`[ here](), or you can download a ZIP file that contains this README, and all the other files you need from [here]().

## <a name="setup"></a>Setting Up the Server
Place the `meteor_setup.sh` script in the same directory as the `Vagrantfile`. You might need to make it executable. Run the following in the Terminal:

``` bash
sudo chmod 755 meteor_setup.sh
```

As it stands, `meteor_setup.sh` wants to set up a server to run your Meteor application at http://www.example.com, using a MondoDB database called `exampledb`. It also wants to create a user called `meteor` which controls what happens in a directory at `/var/www/meteor`, and which lets you log in to your server as `meteor` with the password `meteor`.

###Customizing meteor_setup.sh

At the top of the file, you will find the following lines:

```
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
```
It's probably fine to leave the username and password the way they are. This weak password is not going to cause any problems, so long as you disable logging into the server with a password, as explain in the [Security](#security) section at the end.

If you are working with a real server, out in the world somewhere, you will want to change the values for `server_name`, `root_url` and `mongodb`, so that they correspond to the real names and addresses that your project will be using.

####Testing in a virtual machine
If you are simply testing this in a virtual machine, you may be happy to keep the `example.com` domain name. In this case, you should edit the file at `/etc/hosts` on your work computer, so that it knows to find http://example.com at `10.1.1.2` where your virtual machine is running.

You can edit `/etc/hosts` so that it looks something like this:

```
 127.0.0.1 localhost
 127.0.1.1 hostname # will be different on your computer

 10.1.1.2 example.com
 10.1.1.2 www.example.com

 # The following lines are desirable for IPv6 capable hosts
 ::1     ip6-localhost ip6-loopback
 fe00::0 ip6-localnet
 ff00::0 ip6-mcastprefix
 ff02::1 ip6-allnodes
 ff02::2 ip6-allrouters
```
You'll need root permissions to do this.

###Launching the Installations
Now you are ready to execute `vagrant up` from the Terminal and watch many lines of output steadily chugging through your Terminal window. 

The first part of the output (in white) deals with how Vagrant is installing the operating system and launching the server. When the `meteor__setup` provision script start, the output will appear in colour (mostly green). You can look out for the blue numbered lines that tell you how the installation is proceeding. The red lines are most likely not errors, but it's still worth checking them to see if any are indications that something unexpected has happened. 

>NOTE  
>If you are not using Vagrant, then you can simply upload the `meteor_setup.sh` to your server and run it as root via an `ssh` connection.

When the script completes, you should see something like this in your Terminal window:

``` bash
==> default: 17. Create a dummy raw/ directory to be replaced by the first push
==> default: tree /var/www
==> default: /var/www
==> default: ├── html
==> default: │   └── index.nginx-debian.html
==> default: └── meteor
==> default:     ├── bundle
==> default:     ├── bundle.git
==> default:     │   ├── branches
==> default:     │   ├── config
==> default:     │   ├── description
==> default:     │   ├── HEAD
==> default:     │   ├── hooks
==> default:     │   │   ├── applypatch-msg.sample
==> default:     │   │   ├── commit-msg.sample
==> default:     │   │   ├── post-receive
==> default:     │   │   ├── post-update.sample
==> default:     │   │   ├── pre-applypatch.sample
==> default:     │   │   ├── pre-commit.sample
==> default:     │   │   ├── prepare-commit-msg.sample
==> default:     │   │   ├── pre-push.sample
==> default:     │   │   ├── pre-rebase.sample
==> default:     │   │   └── update.sample
==> default:     │   ├── info
==> default:     │   │   └── exclude
==> default:     │   ├── objects
==> default:     │   │   ├── info
==> default:     │   │   └── pack
==> default:     │   └── refs
==> default:     │       ├── heads
==> default:     │       └── tags
==> default:     ├── deploy.sh
==> default:     └── raw
==> default:         ├── package.json
==> default:         ├── public
==> default:         │   └── server
==> default:         └── README.md
==> default: 
==> default: 16 directories, 18 files
==> default: 
==> default: The server is now ready for you to deploy your meteor app.
==> default: On your development machine, you can now run the deploy_init.sh script
==> default: in the parent folder of your meteor app.
==> default: 
==> default: cd /path/to/meteor_app/..
==> default: cp /path/to/deploy_init.sh .
==> default: sudo chmod 755 deploy_init.sh
==> default: sudo ./deploy_init.sh
````

If you now connect to http:10.1.1.2, you should see the standard **Welcome to nginx!** placeholder page, served by the file at `/var/www/html/index.nginx-debian.html`. The files installed in the `/var/www/meteor` folder are where all the magic will happen.

You'll see a directory at `/var/www/meteor/bundle` that is currently empty. That's where your Meteor app will be, as soon as you deploy it to your server.

>NOTE  
>With Vagrant, this provisioning process will only happen once. When you use `vagrant up` to relaunch the server the next times, all the installed packages will already be in place, and the start up will be much quicker.

##The Secret of How It Works
Let's get a bit ahead of ourselves, so that you can have an idea of what all this means.

Git is a free and open-source version control system. It allows you to keep track of your changes and to work in collaboration with others on the same project, while ensuring that the conflicts that may arise in different versions of the code are kept under control. It does many many things that do not need to concern you here.

Git allows you to create *repositories*  which hold all your code and other media. You can use the command `git push` to synchronise different repositories with each other. The script that you have just run has installed Git on your server, and has create a [bare](https://githowto.com/bare_repositories) repository at `/var/www/meteor/bundle.git`. In the simplest terms, a bare repository is a storeroom where files are simply stored, where no-one is ever going to work.

This `bundle.git` repository is set up so that when you use `git push` to push changes to it from your develompent computer, Git will trigger the script at `/var/www/meteor/bundle.git/hooks/post-receive`. This script will do two things:

* It updates the `raw` directory so that its contents are identical to those in the repository on your development computer. The contents of the `raw` file are currently placeholders. You'll be setting up that repository in a moment, with the script `deploy_init.sh`.
* It calls another script at `/var/www/meteor/deploy.sh`, and this script does all the hard work.

####deploy.sh
The `deploy.sh` script does four things:

1. It copies the  entire current version of `/var/www/meteor/raw/bundle` to a tmp directory
2. It calls `npm install --production` from inside the directory `/var/www/meteor/bundle/serv  so that tmp is ready for delivery
3. It moves the current directory at `/var/www/meteor/bundle` to an `archive` directory and renames `tmp` as bundle
4. It restarts nginx, so that nginx knows about the  content of the new folder at `/var/www/meteor/bundle` 

And that's it! The latest version of your app is now online and active ... Ah, but first let's see how you're going to be preparing everything so that `git push` from your work computer sets all this machinery in motion.

##Setting Up Deployment on your Work Computer
You'll find a script called `deploy_int.sh` [here](), or you can find it in the ZIP file that you can download from [here](). Place this in the parent folder of your Meteor app. As before, you might need to make it executable. Run the following in the Terminal:

``` bash
sudo chmod 755 deploy_init.sh
```
###Customizing deploy_init.sh

At the top of the file, you will find the following lines:

```
 ## << HARD-CODED
  local_user=me      # name of a non-root user with an RSA key pair
  remote_user=meteor # name of user who can ssh in to your server
  ip=10.1.1.2        # IP address of server

  project=barebones  # name of your Meteor project directory

  url=http://www.example.com/     # address to visit from a browser
  ## HARD-CODED >>
```

Change the value of `local_user` to your own user name, and the value of `project` to whatever the name of your Meteor app directory is called. Be sure to use the exact same case, because bash scripts are case-sensitive.

If you're just testing, and you didn't change the settings for `username`, `server_name` and `root_url` in the `meteor_setup.sh` script AND you edited your `/etc/hosts` file to tell your computer where to find http://example.com, then you can leave all the other values as they are. If you *did* make changes to the `meteor_setup.sh` script, then you should mirror those changes here. 

***The deployment process will fail if these values are not correct.***

>NOTE  
>`deploy_init.sh` assumes that you already have Git installed on your work computer. If you don't, and you are working on Linux or Mac, you can simply uncomment lines 96-99, and the script will install Git for you. 

``` bash
 ## Uncomment the next three lines if git is not already installed
 # echo "Ensuring that git is installed..." 
 # apt-get update
 # apt-get install git
```
If you don't and you are working on Windows, then you can find instructions on how to install Git  at one of these sources:

* [git-scm.com](http://git-scm.com/download/win)
* [git-for-windows](https://git-for-windows.github.io/)
* [chocolatey](https://chocolatey.org/packages/git)
* [windows.github.com](http://windows.github.com)

####Logging in with an RSA key pair

You want your `./meteor_deploy` command to run to completion with no further input from you. In particular, you don't want to have to enter a password each time you run it. A secure way of logging on to a remote server is to use an RSA key pair. You may already have such a key pair, or you may have no idea [what it is and what it does](https://help.ubuntu.com/community/SSH/OpenSSH/Keys).

In either case, run the `deploy_init.sh` script a first time as an ordinary non-root user...

```
./deploy_init
```
... and follow the instructions that are appropriate to your situation.

If you already have an RSA key pair, you should see this:

``` bash
************ Checking if an id_rsa.pub file exists ************
It seems that you already have an RSA key pair. Use the
following command to copy the public key to the server at
10.1.1.2. You will be asked for a password. Use the temporary
password that was set in the meteor_setup.sh script that you
ran earlier on the remote server.

su me
ssh-copy-id meteor@10.1.1.2

Then check that you can log in to the server without entering a
password and run exit to log out again:

ssh meteor@10.1.1.2
<Welcome message from server>
exit

When you have done that, you can run this script again as root
using sudo ./deploy_init.
```
If you do not already have an RSA key set up for you on your work computer, you will see something like this  in your Terminal window (the usernames and ip address may be different for you):

``` bash
******** Checking if an id_rsa.pub file exists ********
When deploying your app to the server, you will be logged in to
this computer as 'me'.

You need to create an RSA key pair so that me can push
git files to the server as meteor without your needing to
enter a password.

Run the commands in white below and follow the instructions:

If you decide to use a passphrase when you create the key, make
sure that you will remember it, or that you keep it in a very
safe place, and that you remember where you have kept it.

When you run ssh-copy-id meteor@10.1.1.2, you will be asked for a
password. Use the temporary password that was set in the
meteor_setup.sh script that you ran earlier on the remote server.

su me
ssh-keygen -t rsa
<Follow the instructions>
ssh-copy-id meteor@10.1.1.2

Then check that you can log in to the server without entering a
password and run exit to log out again:

ssh meteor@10.1.1.2
<Welcome message from server>
exit

When you have done that, you can run this script again as root
using sudo ./deploy_init.
```
When you are sure that you can log on to the server without entering a password, you can run the `deploy_init.sh` script again, but this time as root. Here's what you should see:

``` bash
$ sudo ./deploy_init.sh 
1. Create script to push the bundle to the server
2. Create directories to deal with deployment
3. Initialize git in the deployment/current directory

Initialised empty Git repository in /home/me/meteor.example.com/meteor/deployment/current/.git/

Check that the remote repository details are correct:
server	ssh://meteor@10.1.1.2/var/www/meteor/bundle.git (fetch)
server	ssh://meteor@10.1.1.2/var/www/meteor/bundle.git (push)

If not, delete the meteor_deploy file, correct the details in the
HARD-CODED section of deploy_init.sh and run sudo ./meteor_deploy
again.

When you are ready, run `./meteor_deploy` as me.
```
##meteor_deploy

This is it. Everything is ready for you to deploy your Meteor app to your server any time you like with a one-line command.

You'll see that there is a new directory alongside your the directory that holds your Meteor app, and a new script: `meteor_deploy`. Let's look at this in more detail:

``` bash
$ tree -a -L 3 
.
├── barebones
│   ├── client
│   │   ├── main.css
│   │   ├── main.html
│   │   └── main.js
│   ├── .gitignore
│   ├── .meteor
...
│   │   └── versions
│   ├── node_modules
...
│   │   └── regenerator-runtime
...
│   └── server
│       └── main.js
├── deploy_init.sh
├── deployment
│   ├── archive
│   └── current
│       ├── .git
│       ├── public
│       └── tmp
└── meteor_deploy
```
The directory holding your Meteor app (mine is called `barebones`) will be unchanged. But now there's a `deployment` directory which has an (empty) `archive` sub-directory, and a sub-directory called `current` which current contains two folders: `public` and `tmp`.  These folders are required because Phusion Passenger expects to find them. If your project does not use these folders, they will be uploaded anyway, and Passenger will be happy. If your project does use them, they will be overwritten as soon as you run `./meteor_deploy` and Passenger will still be happy.

But there's also a hidden `.git` directory in `deployment/current/`, and that's what makes everything work.

When you run `./meteor_deploy`, three things happen:

* Meteor creates a`tar.gz` bundle of all the files that you need for your production server
* The script extracts this file into the `current` directory, replacing everything that was there before
* The `tar.gz` file itself is renamed and added to the `archive` directory, just in case
* Git is asked to check if there's anything new or changed
* Git is told to push everything new or changed to the remote server, where `/var/www/meteor/bundle.git/post-receive` will get triggered

In your Terminal window, you'll see output from the remote server, telling you what's going on there, and ending with a new view of the Meteor installation on your server. Here's an edited version ,with 123 lines concerning new files removed, to improve your reading pleasure:

``` bash
$ ./meteor_deploy
Changes:                                      
[master dd66cff] Deploy 171126-0307
...  <long list of commit details cut>
 create mode 100644 bundle/star.json
Pushing to 10.1.1.2...
Counting objects: 6386, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (5968/5968), done.
Writing objects: 100% (6386/6386), 6.30 MiB | 5.63 MiB/s, done.
Total 6386 (delta 1511), reused 0 (delta 0)
remote: Executing hooks/post-receive as meteor
remote: Executing deploy.sh as root
remote: 
remote: Running npm install --production in /var/www/meteor/tmp/programs/server
remote: as meteor
remote: 
remote: > fibers@2.0.0 install /var/www/meteor/tmp/programs/server/node_modules/fibers
remote: > node build.js || nodejs build.js
remote: 
remote: `linux-x64-57` exists; testing
remote: Binary is fine; exiting
remote: 
remote: > meteor-dev-bundle@0.0.0 install /var/www/meteor/tmp/programs/server
remote: > node npm-rebuild.js
remote: 
remote: {
remote:   "meteor-dev-bundle": "0.0.0",
remote:   "npm": "5.4.2",
remote:   "ares": "1.10.1-DEV",
remote:   "cldr": "31.0.1",
remote:   "http_parser": "2.7.0",
remote:   "icu": "59.1",
remote:   "modules": "57",
remote:   "nghttp2": "1.25.0",
remote:   "node": "8.8.1",
remote:   "openssl": "1.0.2l",
remote:   "tz": "2017b",
remote:   "unicode": "9.0",
remote:   "uv": "1.15.0",
remote:   "v8": "6.1.534.42",
remote:   "zlib": "1.2.11"
remote: }
remote: npm WARN meteor-dev-bundle@0.0.0 No description
remote: npm WARN meteor-dev-bundle@0.0.0 No repository field.
remote: npm WARN meteor-dev-bundle@0.0.0 No license field.
remote: 
remote: added 124 packages in 4.412s
remote: /var/www/meteor
remote: .
remote: ├── archive
remote: │   └── 171125-1827
remote: ├── bundle
remote: │   ├── date
remote: │   ├── main.js
remote: │   ├── programs
remote: │   ├── README
remote: │   ├── server
remote: │   └── star.json
remote: ├── bundle.git
remote: │   ├── branches
remote: │   ├── config
remote: │   ├── description
remote: │   ├── HEAD
remote: │   ├── hooks
remote: │   ├── index
remote: │   ├── info
remote: │   ├── objects
remote: │   └── refs
remote: ├── deploy.sh
remote: └── raw
remote:         ├── bundle
remote:         ├── package.json
remote:         ├── public
remote:         └── README.md
remote: 
remote: 14 directories, 12 files
remote: 
remote: nginx -t
remote: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
remote: nginx: configuration file /etc/nginx/nginx.conf test is successful
remote: 
remote: service nginx status
remote: ● nginx.service - A high performance web server and a reverse proxy server
remote:    Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
remote:    Active: active (running) since Sun 2017-11-26 00:05:38 UTC; 34ms ago
remote:   Process: 3179 ExecStop=/bin/sleep 1 (code=exited, status=0/SUCCESS)
remote:   Process: 3176 ExecStop=/sbin/start-stop-daemon --quiet --stop --retry TERM/5 --pidfile /run/nginx.pid (code=exited, status=0/SUCCESS)
remote:   Process: 3193 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
remote:   Process: 3188 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
remote:  Main PID: 3214 (nginx)
remote:     Tasks: 20
remote:    Memory: 9.9M
remote:       CPU: 67ms
remote:    CGroup: /system.slice/nginx.service
remote:            ├─3196 Passenger watchdog                                                      
remote:            ├─3199 Passenger core                                                      
remote:            ├─3214 nginx: master process /usr/sbin/nginx -g daemon on; master_process on
remote:            ├─3216 nginx: worker process                           
remote:            └─3217 nginx: worker process                           
remote: 
remote: Nov 26 00:05:37 ubuntu-xenial systemd[1]: Starting A high performance web server and a reverse proxy server...
remote: Nov 26 00:05:38 ubuntu-xenial systemd[1]: Started A high performance web server and a reverse proxy server.
remote: Deploy complete
To ssh://meteor@10.1.1.2/var/www/meteor/bundle.git
 * [new branch]      master -> master
The update should now be visible at http://www.example.com/
```

You'll notice that the tree view of the `/var/www/meteor` directory shows that the original `bundle` directory has been moved to the `archive` directory, and renamed with a timestamp. The new `bundle` has all the juicy Meteor goodness that makes your app work. If you visit your application's URL in your browser, you should see that your app is online. Yeah!

##Troubleshooting
Things will go wrong if you give them the slightest opportunity. If you've got this far and everything is working perfectly, then congratulations! If you have encountered any difficulties, create an Issue, and I'll see how we can work out a solution together.

##End note
OK, that was long: a long way round to get to the point where you simply need to point your Terminal at the parent folder of your Meteor project, and run `./meteor_deploy`. But now perhaps you understand a bit more about how a Meteor project is delivered by a production server, and how Git can help you to automate tasks.

The `meteor_setup.sh` and `deploy_init.sh` scripts are well commented, so you should be able to work throught them and understand what is going on at each step and why. If your project has additional dependencies, then you might like to fork this repository, customize the install and deploy scripts and make your versions available for others whose Meteor environment is similar to yours.

As always, I'm here to help.

Happy  meteor_deploy!

James