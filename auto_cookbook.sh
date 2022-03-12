#!/bin/bash
echo "Creating the 'mymongodb' cookbook: "

cd ~/chef-repo/cookbooks
chef generate cookbook mymongodb
chef generate recipe mymongodb common

cat >  mymongodb/recipes/common.rb <<-MYEOF
execute "update_hosts" do
  command '
  echo "10.11.12.99 chefdev.yourdomain.org chefdev" >>/etc/hosts; 
  echo "10.11.12.100 chefsrv.yourdomain.org chefsrv" >>/etc/hosts; 
  for i in {1..3}; do 
     echo "10.11.12.10\$i mongodb\$i.yourdomain.org mongodb\$i" >>/etc/hosts; 
  done; 
     touch /var/lock/hosts_updated'
  not_if do ::File.exists?('/var/lock/hosts_updated') end
end 

template "/etc/chef/client.rb" do
  source "client.rb.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end
MYEOF

echo "Setting up a (very) basic /etc/client.rb file: "
chef generate template mymongodb client.rb

cat > mymongodb/templates/client.rb.erb <<-MYEOF
log_level        :info
log_location     STDOUT
chef_server_url  'https://chefsrv.yourdomain.org/'
validation_client_name 'chef-validator'
MYEOF

echo "Adding mongodb repositories to yum: "
chef generate template mymongodb mongodb.repo
cat > mymongodb/templates/mongodb.repo.erb <<-MYEOF
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
MYEOF

echo "Creating the recipe for our main course, mongodb: "
cat > mymongodb/recipes/default.rb <<-MYEOF
include_recipe "mymongodb::common"

template "/etc/yum.repos.d/mongodb.repo" do
  source "mongodb.repo.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end

# package "mongodb-org"

# template "/etc/mongod.conf" do
#   source "mongod.conf.erb"
#   mode 0644
#   owner "root"
#   group "root"
#   action :create
# end

# service "mongod" do
#   action [:start, :enable]
# end
MYEOF

echo "Generating a mongod config file template: "
chef generate template mymongodb mongod.conf

echo "Inserting butchered mongod.conf file: "
cat > mymongodb/templates/mongod.conf.erb <<-MYEOF
# mongod.conf
# where to log
logpath=/var/log/mongodb/mongod.log
logappend=true
# fork and run in background
fork=true
#port=27017
dbpath=/var/lib/mongo
# location of pidfile
pidfilepath=/var/run/mongodb/mongod.pid
# Listen to local interface only. Comment out to listen on all interfaces. 
#bind_ip=127.0.0.1
# Disables write-ahead journaling
nojournal=false
# Enables periodic logging of CPU utilization and I/O wait
#cpu=true
# Turn on/off security.  Off is currently the default
#noauth=true
#auth=true
# Verbose logging output.
#verbose=true
# Inspect all client data for validity on receipt (useful for developing drivers)
#objcheck=true
# Enable db quota management
#quota=true
# Set oplogging level where n is
#   0=off (default), 1=W, 2=R, 3=both, 7=W+some reads
#diaglog=0
# Ignore query hints
nohints=false
# Enable the HTTP interface (Defaults to port 28017).
httpinterface=false
# Turns off server-side scripting.  This will result in greatly limited functionality
noscripting=false
# Turns off table scans.  Any query that would do a table scan fails.
notablescan=false
# Disable data file preallocation.
noprealloc=false
# Specify .ns file size for new databases.
# nssize=<size>
# Replication Options
# in replicated mongo databases, specify the replica set name here
replSet=shard01
# maximum size in megabytes for replication operation log
oplogSize=1024
# path to a key file storing authentication info for connections between replica set members
#keyFile=/path/to/keyfile
MYEOF

echo "Generating a mongo config script for replication: " 
chef generate template mymongodb mongoconfig.js
echo 'rs.initiate({"_id":"shard01","members":[{"_id":0,"host":"mongodb1.yourdomain.org:27017"},{"_id":1,"host":"mongodb2.yourdomain.org:27017"},{"_id":2,"host":"mongodb3.yourdomain.org:27017"}]})' > mymongodb/templates/mongoconfig.js.erb

echo "Generating a special recipe for the primary mongod server:" 
chef generate recipe mymongodb mongod_primary

cat > mymongodb/recipes/mongod_primary.rb <<-MYEOF
include_recipe "mymongodb"

template "/tmp/mongoconfig.js" do
  source "mongoconfig.js.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end
MYEOF
execute "configure_primary" do
  command "/usr/bin/mongo < /tmp/mongoconfig.js"
end
MYEOF

echo "Uploading cookbook: "
knife cookbook upload mymongodb

echo "Exporting cookbooks directory to /vagrant, just for fun: " 
cd ../
cp -R cookbooks /vagrant

echo "Creating the 'Tomcat' cookbook: "

cd ~/chef-repo/cookbooks
chef generate cookbook tomcat_v8
chef generate attribute tomcat_v8 default
touch ~/chef-repo/cookbooks/tomcat_v8/Berksfile

cat > tomcat_v8/attributes/default.rb <<-MYEOF
default['tomcat_v8']['tomcat_url']=”http://archive.apache.org/dist/tomcat/tomcat-8/”
default['tomcat_v8']['tomcat_version']=”8.5.15″
default['tomcat_v8']['tomcat_install_dir']=”/opt/apache/tomcat”
default['tomcat_v8']['tomcat_user']=”tomcat”
default['tomcat_v8']['tomcat_auto_start']=”true”
MYEOF

cat > ~/chef-repo/cookbooks/tomcat_v8/Berksfile <<-MYEOF
source 'https://supermarket.chef.io'
cookbook 'java_se', '= 8.131.0'
metadata
MYEOF

cd ~/chef-repo/cookbooks/tomcat_v8
berks install
berks upload --no-freeze

cat > ~/chef-repo/cookbooks/tomcat_v8/recipes/default.rb <<-MYEOF

tomcat_url=node['tomcat_v8']['tomcat_url']
tomcat_version=node['tomcat_v8']['tomcat_version']
tomcat_install_dir=node['tomcat_v8']['tomcat_install_dir']
tomcat_user=node['tomcat_v8']['tomcat_user']
tomcat_auto_start=node['tomcat_v8']['tomcat_auto_start']

group “tomcat”

user “tomcat” do
        group “tomcat”
        system true
        shell “/bin/bash”
end

directory “#{tomcat_install_dir}” do
  owner 'tomcat'
  group 'tomcat'
  mode '0755'
  recursive true
  action :create
end

## Include the dependencies
include_recipe “java_se”

## Download the tomcat package
download_url=”#{tomcat_url}”+”v#{tomcat_version}”+”/bin/apache-tomcat-#{tomcat_version}.tar.gz”

script “Download Apache Tomcat version #{tomcat_version}” do
        interpreter “bash”
        user “#{tomcat_user}”
        cwd “/tmp”
        code <<-EOH
                wget “#{download_url}” -O “/tmp/apache-tomcat-#{tomcat_version}.tar.gz”
                #mkdir -p #{tomcat_install_dir}
        EOH
end

## Extract the package

script “Extracting the Apache Tomcat Package” do
        interpreter “bash”
        user “#{tomcat_user}”
        cwd “/tmp”
        code <<-EOH
                tar -zxvf /tmp/apache-tomcat-#{tomcat_version}.tar.gz -C #{tomcat_install_dir}
        EOH
end

## Move the unzipped package to /opt/apache/tomcat/apache-tomcat

script “Move the package” do
        interpreter “bash”
        user “#{tomcat_user}”
        cwd “/tmp”
        code <<-EOH
                if [[ ! -d /opt/apache/tomcat/apache-tomcat  ]] ; then
                        cd #{tomcat_install_dir} ; mv apache-tomcat-* apache-tomcat
                else
                        echo “Directory already exists”
                fi
        EOH
end

## Start the tomcat instance

script “Start the tomcat instance” do
        interpreter “bash”
        user “#{tomcat_user}”
        cwd “/tmp”
        code <<-EOH
                /opt/apache/tomcat/apache-tomcat/bin/startup.sh
        EOH
End
MYEOF