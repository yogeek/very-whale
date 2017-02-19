#!/bin/bash

source env_cluster.sh "$@"

loghighlight "====================== SWARM INIT ======================"

# Connect to the manager 1
loghighlight "Initializing the swarm..."
dm use ${FIRST_MANAGER}
# Init the swarm on the manager with its own IP (it manages itself for the moment)
docker swarm init --advertise-addr $(dm ip ${FIRST_MANAGER})

# Get the tokens for future machines to join the swarm cluster
dm use ${FIRST_MANAGER}
TOKEN_MANAGER=$(docker swarm join-token manager -q)
TOKEN_WORKER=$(docker swarm join-token worker -q)

echo "Tokens :"
echo "  Manager = ${TOKEN_MANAGER}"
echo "  Worker = ${TOKEN_WORKER}"
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

loghighlight "Swarm cluster ready to host services ! "

loghighlight "========================================================"