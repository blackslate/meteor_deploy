# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  
  config.vm.box = "ubuntu/xenial64"

  config.vm.network "private_network", ip: "10.1.1.2"

  config.vm.provision :shell, :path => "meteor_setup.sh"

end