#!/bin/bash

# Load cluster configuration
source env_cluster.sh $1

# Connect to the main manager
dm use ${FIRST_MANAGER}

loghighlight "===================== WORDPRESS DEPLOY ====================="

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

# Waiting for Master service to be running
wait_service "side=backend" 1

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


# Waiting for Master service to be running
wait_service "side=frontend" ${WORDPRESS_SERVICE_REPLICAS}

# Display services
loghighlight "---------- Services list :"
docker service ls
echo ""

echo "Wordpress app is deployed on swarm cluster !"
FIRST_MANAGER_IP="$(dm ip ${FIRST_MANAGER})"
WORDPRESS_URL="http://${FIRST_MANAGER_IP}:${WORDPRESS_SERVICE_PUBLISHED_PORT}"
echo ""
loghighlight "Wordpress is accessible from ${WORDPRESS_URL} "
echo "(or any other node of the swarm cluster)"
echo ""

loghighlight "========================================================"
