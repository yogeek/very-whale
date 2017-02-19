#!/bin/bash

source env_cluster.sh "$@"

loghighlight "====================== STACK CLEANING ======================"

# Connect to the first manager
echo "Cleaning the stack..."
dm use ${FIRST_MANAGER}
docker stack rm wordpress_stack

# Display the nodes
loghighlight "---------- Stack list :"
docker stack ls

loghighlight "Stack removed ! "

loghighlight "========================================================"
