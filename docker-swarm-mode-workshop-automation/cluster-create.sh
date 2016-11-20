#!/bin/bash

##############################################################################################
# This script aims to automate a Docker 1.12 swarm-mode cluster creation 
# and the deployment of a wordpress stack on it.
#
# Prerequisites :
# 	- docker 1.12 (https://docs.docker.com/engine/installation/)
# 	- docker-machine 0.8.2 (https://docs.docker.com/machine/install-machine/)
# 	- docker-machine "bash completion scripts" 
#	  (https://docs.docker.com/machine/install-machine/#/installing-bash-completion-scripts)
#
# Configuration must be specified in "env_cluster.sh".
#
##############################################################################################

# Load cluster configuration
source env_cluster.sh

# Create Managers machines
loghighlight "Creating managers..."
for manager in ${MANAGERS_LIST[*]}; do
    dm create -d virtualbox --virtualbox-memory=512 $manager
done

# Create Workers machines
loghighlight "Creating workers..."
for worker in ${WORKERS_LIST[*]}; do
    dm create -d virtualbox --virtualbox-memory=512 $worker
done

# Check machines
echo ""
loghighlight "---------- Machines list :"
dm ls
echo ""

# Connect to the manager 1
echo "Initializing the swarm..."
dm use ${FIRST_MANAGER}
# Init the swarm on the manager with its own IP (it manages itself for the moment)
docker swarm init --advertise-addr $(dm ip ${FIRST_MANAGER})

# Get the tokens for future machines to join the swarm cluster
dm use ${FIRST_MANAGER}
TOKEN_MANAGER=$(docker swarm join-token manager -q)
TOKEN_WORKER=$(docker swarm join-token worker -q)

echo "Tokens :"
echo "	Manager = ${TOKEN_MANAGER}"
echo "	Worker = ${TOKEN_WORKER}"
echo ""

# Join the other nodes from the MANAGER_LIST as managers
loghighlight "Joining the other managers..."
for node in ${MANAGERS_LIST[@]:1}; do
	dm use $node
	docker swarm join \
    	--token ${TOKEN_MANAGER} \
    	$(dm ip ${FIRST_MANAGER}):2377 \
    	--advertise-addr $(dm ip $node)
done

# Join the worker nodes as... workers !
loghighlight "Joining the workers..."
for node in ${WORKERS_LIST[@]}; do
	dm use $node
	docker swarm join \
    	--token ${TOKEN_WORKER} \
    	$(dm ip ${FIRST_MANAGER}):2377 \
    	--advertise-addr $(dm ip $node)
done

# Back to the manager
dm use ${FIRST_MANAGER}

# Display the nodes
loghighlight "---------- Swarm nodes list :"
docker node ls
echo ""

# Create application network
loghighlight "Creating application overlay network..."
docker network create -d overlay ${WORDPRESS_NETWORK_NAME}

# Declare mysql service (1 instance because databases are specific services to replicate)
loghighlight "Creating mysql service..."
docker service create --name ${MYSQL_SERVICE_NAME} \
	--env MYSQL_DATABASE=${MYSQL_DATABASE} \
	--env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
	--network ${WORDPRESS_NETWORK_NAME} \
	--label side=backend \
	${MYSQL_DOCKER_IMAGE}

# Waiting for mysql service to be running
while [[ ! $(docker service ls -f label=side=backend | grep -v REPLICAS | grep "1/1") ]]; do 
	echo "waiting for mysql service to be ready..."
	sleep 10
done
echo "MYSQL is ready !"
echo ""

# Declare wordpress service ($NB_INSTANCES instances)
loghighlight "Creating wordpress service..."
docker service create --name ${WORDPRESS_SERVICE_NAME} \
	--env WORDPRESS_DB_HOST=${MYSQL_SERVICE_NAME} \
	--env WORDPRESS_DB_PASSWORD=${MYSQL_ROOT_PASSWORD} \
	--network ${WORDPRESS_NETWORK_NAME} \
	--replicas ${WORDPRESS_SERVICE_REPLICAS} \
	--publish ${WORDPRESS_SERVICE_PUBLISHED_PORT}:80 \
	--label side=frontend \
	${WORDPRESS_DOCKER_IMAGE} 

# Waiting for wordpress service to be running
while [[ ! $(docker service ls -f label=side=frontend | grep -v REPLICAS | grep "${WORDPRESS_SERVICE_REPLICAS}/${WORDPRESS_SERVICE_REPLICAS}") ]]; do 
	echo "waiting for ${WORDPRESS_SERVICE_NAME} service to be ready..."
	sleep 10 
done
echo "WORDPRESS is ready !"
echo ""

# Display services
loghighlight "---------- Services list :"
docker service ls
echo""

echo "Wordpress app is deployed on swarm cluster !"
FIRST_MANAGER_IP="$(dm ip ${FIRST_MANAGER})"
WORDPRESS_URL="http://${FIRST_MANAGER_IP}:${WORDPRESS_SERVICE_PUBLISHED_PORT}"
echo ""
loghighlight "Wordpress is accessible from ${WORDPRESS_URL} "
echo "(or any other node of the swarm cluster)"
echo ""

# Start a cluster visualizer container to display the swarm deployment in a web page
# Can be started on any node of the cluster
loghighlight "Creating visualizer service..."
docker service create --name=viz \
	--publish=${VISUALIZER_PORT}:8080/tcp \
	--constraint=node.role==manager \
	--mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
	manomarks/visualizer

# Waiting for viz service to be running
while [[ ! $(docker service ls -f name=viz | grep -v REPLICAS | grep "1/1") ]]; do 
	echo "waiting for ${WORDPRESS_SERVICE_NAME} service to be ready..."
	sleep 10
done
echo "VIZ is ready !"
echo ""

VISUALIZER_IP=$(dm ip ${FIRST_MANAGER})
loghighlight "Visualizer is accessible on : http://${VISUALIZER_IP}:${VISUALIZER_PORT}"
echo ""
echo "Whale done ! :-)"
echo ""