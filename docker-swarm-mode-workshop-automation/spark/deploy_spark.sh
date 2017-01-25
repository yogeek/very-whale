#!/bin/bash

# Load cluster configuration
source spark_env.sh $1

loghighlight "===================== SPARK DEPLOY ====================="

# Create application network
loghighlight "Creating application overlay network..."
docker network create \
	--driver overlay \
	--attachable \
	${SPARK_NETWORK_NAME}

# Declare Spark Master service
loghighlight "Creating master service..."
gcloud docker -- service create \
	--with-registry-auth \
	--name ${SPARK_MASTER_SERVICE_NAME} \
        --network ${SPARK_NETWORK_NAME} \
        --replicas ${SPARK_MASTER_SERVICE_REPLICAS} \
	--constraint=node.role==manager \
        --label kind=master \
	--port mode=ingress,target=7077,published=7077,protocol=tcp \
	--port mode=ingress,target=8080,published=80,protocol=tcp \
        ${SPARK_MASTER_DOCKER_IMAGE} \
        /start-master

# Waiting for Master service to be running
wait_service "kind=master" ${SPARK_MASTER_SERVICE_REPLICAS}

# Declare Spark Worker service
loghighlight "Creating worker service..."
gcloud docker -- service create \
	--with-registry-auth \
	--name ${SPARK_WORKER_SERVICE_NAME} \
        --network ${SPARK_NETWORK_NAME} \
        --replicas ${SPARK_WORKER_SERVICE_REPLICAS} \
        --label kind=worker \
        ${SPARK_WORKER_DOCKER_IMAGE} \
        /start-worker

# Waiting for Worker service to be running
wait_service "kind=worker" ${SPARK_WORKER_SERVICE_REPLICAS}

# Display services
loghighlight "---------- Services list :"
docker service ls
echo""

echo "Spark app is deployed on swarm cluster !"
echo ""

loghighlight "========================================================"
