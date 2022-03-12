# -*- mode: ruby -*-

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/centos-6.6"
# Chef-server box: 
  config.vm.define "chefsrv" do |chefsrv|
    chefsrv.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "1024"]
      v.customize ["modifyvm", :id, "--name", "chefsrv"]
    end
    chefsrv.vm.box = "bento/centos-6.6"
    chefsrv.vm.host_name = "chefsrv.yourdomain.org"    
    chefsrv.vm.network "private_network", ip: "10.11.12.100"
    chefsrv.vm.provision :shell, path: "chefsrv.sh"
  end
# ChefDK box: 
  config.vm.define "chefdev" do |chefdev|
    chefdev.vm.provision :shell, path: "chefdev.sh"
    chefdev.vm.provision "chef_client" do |chef|
      chef.chef_server_url = "https://10.11.12.100:443"
      chef.validation_key_path = "chef-validator.pem"
      chef.environment = "_default"
      chef.delete_node = true
      chef.delete_client = true
    end
    chefdev.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", "512"]
      v.customize ["modifyvm", :id, "--name", "chefdev"]
    end
    chefdev.vm.box = "bento/centos-6.6"
    chefdev.vm.host_name = "chefdev.yourdomain.org"
    chefdev.vm.network "private_network", ip: "10.11.12.99"
  end
# MongoDB boxes:

# We'll bring up the mongo boxes in reverse order, as we would like mongodb1 to become PRIMARY,
# however all mongos need to be up and running *before* we initiate replication. 

  (1..3).reverse_each do |i|
    config.vm.define "mongodb#{i}" do |mongodb|
      mongodb.vm.provision :shell, path: "mongodb.sh"
      mongodb.vm.provision "chef_client" do |chef|
        chef.chef_server_url = "https://10.11.12.100:443"
        chef.validation_key_path = "chef-validator.pem"
        chef.environment = "MONGODEV"
        chef.delete_node = true
        chef.delete_client = true
      end
      mongodb.vm.provider "virtualbox" do |v|
          v.customize ["modifyvm", :id, "--memory", "512"]
          v.customize ["modifyvm", :id, "--name", "mongodb#{i}"]
      end
      mongodb.vm.box = "bento/centos-6.6"
      mongodb.vm.host_name = "mongodb#{i}.yourdomain.org"
      mongodb.vm.network "private_network", ip: "10.11.12.10#{i}"
    end
  end
end