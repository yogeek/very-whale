# create-generic.sh
# 
# This allows to add an existing remote server as in Docker-Machine
# It uses the 'generic' driver : https://docs.docker.com/machine/drivers/generic/
#
# Prequisites :
# 	- a remote server exists with a sudo account 'admin'
# 	- Docker & Docker-Machine are installed on your local machine
#
# Use Case example : you have a virtual machine running on your laptop 
# and you want to install Docker and manipulate it from your local terminal
# 
# Tested with :
# 	- local laptop on Windows 10 with 
# 		* Docker 17.03.0-ce
#		* Docker-Machine 0.10.0
#		* GitBash
# 	- a 'remote' fresh ubuntu virtual machine (created with virtualbox)
#		* configured with 'bridge' network
#		* the 'admin' account having sudo 
#		* 'openssh-server' installed and running (service ssh start)
#		* passwordless sudo access allowed (using visudo by having this line 'sudo ALL=(ALL) NOPASSWD:ALL')

REMOTE_IP=192.168.0.16
REMOTE_ADMIN=admin

DOCKER_MACHINE_NAME=my-docker-machine

# ON LOCAL LAPTOP : open a terminal (GitBash for example)
# Create public, private key pair without passphrase 
ssh-keygen -t rsa 

# Copy 
ssh-copy-id $REMOTE_ADMIN@$REMOTE_IP

# Check that the following command work without password
# ssh -i ~/.ssh/id_rsa admin@$REMOTE_IP 

# Create docker machine named 'my-docker-machine' with generic driver
# The following steps are done :
#	- Importing SSH key
#	- Install Docker if not present
#	- Copy certs to both machines
#	- Starting Docker 
docker-machine.exe create -d generic \
						  --generic-ip-address $REMOTE_IP \
						  --generic-ssh-user $REMOTE_ADMIN \
						  --generic-ssh-key=$HOME/.ssh/id_rsa \
						  $DOCKER_MACHINE_NAME

# You must now see your new docker-machine in the list
docker-machine ls

# You can connect to its Docker Engine with the local docker client with :
eval $(docker-machine env $DOCKER_MACHINE_NAME)

# Enjoy :-)
docker run whalepants/pants

# To 'unconnect' from the remote Docker Engine :
eval $(docker-machine env -u)  