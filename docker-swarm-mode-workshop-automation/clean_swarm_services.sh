#!/bin/bash

# Load cluster configuration
source env_cluster.sh $1

loghighlight "====================== SWARM CLEAN ======================"

# Connect to the manager 1
echo "Cleaning the services..."
dm use ${FIRST_MANAGER}
docker service rm $(docker service ls -q)

echo "Cleaning the network..."
docker network rm ${WORDPRESS_NETWORK_NAME}

# Display the nodes
loghighlight "---------- Swarm services list :"
docker service ls

loghighlight "Swarm cluster ready to host services ! "

loghighlight "========================================================"
