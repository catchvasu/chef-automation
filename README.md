vagrant-chef-mongodb & tomcat Setup using Chef
===============================================

PREREQUISITES: 

1. VirtualBox needs to be installed on your local machine.
2. Vagrant needs to be installed on your local machine.
3. Chef Client needs to be installed and in a working state on your local machine. Vagrant will use your local Knife in order to add/remove your nodes to/from the Chef server.
4. Git needs to be installed and in a working state on your local machine.

Once you've got all that in place, you should be ready to go. Yay!!!  

INSTALLATION: 

- Check out this git repo, just place it anywhere on your system, e.g. in your home directory: 

cd ~

git clone git@github.com:catchvasu/chef-automation.git

- Cd into the new directory created:  

cd vagrant-chef-mongodb
- NOTE: If you're not yet familiar with Vagrant, this could be a good moment to take a quick look at the Vagrant documentation: 
https://docs.vagrantup.com/v2/ 

- Take a quick look at the Vagrantfile and the bootstrap files, to see what we have there. Then type: 

vagrant up

==============================================================================================

NOTES: 

After a successful Vagrant run, you will have: 
- 1x Chef Server with 1GB RAM named 'chefsrv' on '10.11.12.100'. 
- 1x ChefDK Server with your knife ready for action with 512MB RAM named 'chefdev' on '10.11.12.99'. 
- 3x MongoDB servers with 512MB RAM, named 'mongodb1', 'mongodb2', 'mongodb3' on '10.11.12.101..103". 
- the 3x mongodb servers will form a replica set named 'shard01' having 'mongodb3' set as PRIMARY. 

Each machine will check in to the Chef Server automagically during the build process. 
In the end, you can connect to any of the 5 machines above using the "vagrant ssh machine_name" command. 

The Chef server's web interface will also be available. Point your browser to https://10.11.12.100/ , accept the makeshift SSL certificate (you might need to add a security exception) then use the admin credentials found on the first page. 
==============================================================================================

A Vagrant script framework example that provisions a Chef Server, a ChefDK box, generates a cookbook, then builds 3x mongodb replica set servers, and configures replication between them. 

- play around with Vagrant in conjunction with Chef as a provisioner. 
- learn how to set up Chef, provision a Chef Server and a ChefDK box, and configure everything programmatically. 
- create a small cookbook for spawning up MongoDB servers. 
- build 3x MongoDB boxes with Chef using my own cookbook and recipes created above. 
- set up replication between the 3x Mongo boxes, using a simple Chef recipe to configure the replica set. 
- automate all of the above down to a single "vagrant up" command. 
- sit back and watch The Blinkenlights as it all comes together, with no interaction required. 
 
==============================================================================================

WHAT WILL IT DO? : 

If all goes well, you will see Vagrant downloading the 'chef/centos-6.6'
This is just a vanilla CentOS 6.6 Virtualbox image, we'll still have to install Chef on top of it. 
Once the image download is complete, Vagrant will start to build out the 5x virtual machines and go through the following steps: 

- Bootstrap, install, and configure 'chefsrv', your Chef Server. 
- Bootstrap and install 'chefdev', your ChefDK and Chef client machine. 
- Download chef-repo, and will configure knife.rb on 'chefdev'. 
- Create a 'vagrant' Chef user, you can find his initial password sourced inside 'bootstrap_chefdev.sh'. Do not forget to change it later on! (ahem.) 
- Generate a cookbook called 'mymongodb', then add some recipes and some templates to it. Find them all sourced inline inside the bootstrap_chefdev.sh file, if you would like to change anything. 
- Upload the cookbook to the Chef server, and also export 'cookbooks' into your working directory for your viewing pleasure. 
- Register all nodes, including itself, with the chef server. It will export node definitions as JSON files under the 'nodes' directory, if you want to take a look at them. 
- Set up a 'MONGODEV' environment to place the mongo boxes into. The two Chef boxes will remain in the "_default" environment. 
- Create a new 'mongoserver' role for the mongodb machines and will update all run lists accordingly. It will export the definition into the 'roles' directory, for later review. 
- After the cooking part is done, and the bootstrapping phase is over, 'chefdev' will check itself in with the Chef server and execute its own run_list. 
- Bootstrap and install the x3 mongodb servers. 
- Bootstrapping will be minimal, it will only install Chef Client, then hands over the machines to Chef for provisioning. 
- Using the cookbook we've created above, Chef will configure the mongodb repository, and then download and configure mongod on the 3x mongodb servers. 
- once the 3rd mongo is up, Chef will configure mongodb replication across the 3x mongo servers, using a separate recipe called 'mymongodb::mongod_primary'. This recipe will inject a JavaScript configuration file via the mongo console, in order to complete the installation.
- Create a new 'tomcat_8' cookbook with all required configurations
- Install the tomcat on Virtual box.

ONCE YOU'RE DONE: 

- You can verify your installation by connecting to the machines, using "vagrant ssh machine_name". 
- You can check out the state of the mongodb replication by logging on to any of the mongod machines, and typing 'mongo'. 
- From the mongo console, you can issue your favourite commands like: 

rs.conf() , db.isMaster() , or rs.status() , in order to check out the state of the replica set. 

Thanks,
Vasu
==============================================================================================