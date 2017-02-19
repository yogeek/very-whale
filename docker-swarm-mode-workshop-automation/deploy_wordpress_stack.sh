#!/bin/bash

source env_cluster.sh "$@"

loghighlight "====================== STACK DEPLOY ======================"

# Connect to the first manager
echo "Deploying the stack..."
dm use ${FIRST_MANAGER}
docker stack deploy -c docker-compose.yaml wordpress_stack

# Display the nodes
loghighlight "---------- Stack list :"
docker stack ls

loghighlight "Stack deployed on swarm cluster ! "

loghighlight "========================================================"
