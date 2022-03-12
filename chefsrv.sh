#!/usr/bin/env bash

#echo "Updating packages: "
#yum update -y

cd /vagrant
echo "Downloading Chef server: "
wget -nv -nc https://packages.chef.io/files/stable/chef-server/12.17.33/el/7/chef-server-core-12.17.33-1.el7.x86_64.rpm
echo "Installing Chef server: "
rpm -Uvh chef-server-core-12.17.33-1.el7.x86_64.rpm
echo "Setting up Chef server: "
chef-server-ctl reconfigure
echo "Running some basic tests: "
chef-server-ctl test

echo "Exporting keys: "
cp /etc/chef-server/admin.pem /vagrant
cp /etc/chef-server/chef-validator.pem /vagrant
echo "...DONE!"