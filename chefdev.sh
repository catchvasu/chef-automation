#!/usr/bin/env bash

#echo "Updating packages: "
#yum update -y

echo "Installing git, plus a few more packages: "
yum install git nano -y

echo "Downloading ChefDK: "
cd /vagrant
wget -nv -nc https://packages.chef.io/files/stable/chefdk/4.13.3/el/7/chefdk-4.13.3-1.el7.x86_64.rpm
     
echo "Installing ChefDK: "
rpm -Uvh chefdk-4.13.3-1.el7.x86_64.rpm
echo "Verifying installation: "
chef verify

echo "Setting ChefDK Ruby as the system Ruby in .bash_profile: "
echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile

echo "Cloning Chef-repo: "
cd ~
git clone git://github.com/chef/chef.git

echo "Setting up .chef directory, copying keys: "
mkdir .chef
cp /vagrant/chef-validator.pem ~/.chef
echo

echo "Initialising Knife, setting up an initial user: "
echo "We pipe in the password as a workaround, because knife doesn't seem to accept the '--password' command line option as stated in the docs..." 
echo 'y0urpassword@here' | knife configure -i -y -s "https://10.11.12.100:443" --admin-client-key /vagrant/admin.pem -r ~/chef-repo --validation-key ~/.chef/chef-validator.pem --defaults 2>/dev/null
echo "knife[:editor] = '/bin/nano'" >> ~/.chef/knife.rb

# Creating a sample cookbook for you: 
chmod 744 /vagrant/auto_cookbook.sh
/vagrant/auto_cookbook.sh

echo "Creating a new environment for the mongo boxes: "
knife environment create MONGODEV -d "MongoDB Sandbox Environment"

echo "Creating a basic role file: "
mkdir -p /vagrant/roles
echo '{"name":"mongoserver","description":"","json_class":"Chef::Role","default_attributes":{},"override_attributes":{},"chef_type":"role","run_list":["recipe[mymongodb]"],"env_run_lists":{}}' > /vagrant/roles/mongoserver_role.json

echo "Setting up a role: "
knife role from file /vagrant/roles/mongoserver_role.json

echo "Creating basic server node JSON files: "
mkdir -p /vagrant/nodes
for i in {1..3}
do
  echo '{"name":"mongodb'$i'.yourdomain.org","chef_environment":"MONGODEV","run_list":[],"normal":{}}' > /vagrant/nodes/mongodb$i.yourdomain.org.json
done

echo "Reading in mongodb nodes from JSON from the 'nodes' directory: "
c=0
for i in $( ls /vagrant/nodes/mongodb* )
do
  knife node from file $i
  let c++
done

echo "Added $c nodes. "

echo "Associating role with nodes: "
for (( i=1; i<=$c; i++ ))
do
  knife node run_list add mongodb$i.yourdomain.org 'role[mongoserver]'
done

echo "All mongod-s must be up and running in order to initiate a replica set! "
echo "Applying the special recipe to the third mongo server of the cluster: "
knife node run_list add mongodb1.yourdomain.org 'recipe[mymongodb::mongod_primary]'

echo "Creating a node definition and a run_list for ourselves as well: "
echo '{"name":"chefdev.yourdomain.org","chef_environment":"_default","run_list":[],"normal":{}}' > /vagrant/nodes/chefdev.yourdomain.org.json
knife node from file /vagrant/nodes/chefdev.yourdomain.org.json
knife node run_list add chefdev.yourdomain.org 'recipe[mymongodb::common]'
echo "So Automation! Many WOW!!! Such DONE! "