# -*- mode: ruby -*-
# vi: set ft=ruby :

dir = Dir.pwd

Vagrant.configure("2") do |config|

  # Configurations from 1.0.x can be placed in Vagrant 1.1.x specs like the following.
  config.vm.provider :virtualbox do |v|
	  v.customize ["modifyvm", :id, "--memory", 512]
  end

  # Default Box
  config.vm.box = "debian607"
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-607-x64-vbox4210-nocm.box"
  config.vm.hostname = "icewp"
  config.vm.network :private_network, ip: "192.168.99.99"
  config.ssh.forward_agent = true
   
  # Drive mapping
  config.vm.synced_folder "database/", "/srv/database"
  config.vm.synced_folder "config/", "/srv/config"
  config.vm.synced_folder "config/nginx/sites/", "/etc/nginx/custom-sites"
  config.vm.synced_folder "www/", "/srv/www/", :owner => "www-data", :extra => 'dmode=775,fmode=774'

  # Customfile - POSSIBLY UNSTABLE
  if File.exists?('Customfile') then
    eval(IO.read('Customfile'), binding)
  end

  # Provisioning
  if File.exists?('provision/provision-pre.sh') then
    config.vm.provision :shell, :path => File.join( "provision", "provision-pre.sh" )
  end

  if File.exists?('provision/provision-custom.sh') then
    config.vm.provision :shell, :path => File.join( "provision", "provision-custom.sh" )
  else
    config.vm.provision :shell, :path => File.join( "provision", "provision.sh" )
  end

  if File.exists?('provision/provision-post.sh') then
    config.vm.provision :shell, :path => File.join( "provision", "provision-post.sh" )
  end
end
