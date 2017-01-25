#!/bin/bash

# Load cluster configuration
source spark_env.sh $1

export VISUALIZER_PORT=8080

loghighlight "===================== STARTING VIZ ====================="

FIRST_MANAGER_IP="$(dm ip ${FIRST_MANAGER})"
#SPARK_MASTER_URL="http://${FIRST_MANAGER_IP}:${SPARK_MASTER_SERVICE_PUBLISHED_PORT}"
#echo ""
#loghighlight "Spark UI is accessible from ${SPARK_MASTER_URL} "
#echo "(or any other node of the swarm cluster)"
echo ""

# Start a cluster visualizer container to display the swarm deployment in a web page
# Can be started on any node of the cluster
loghighlight "Creating visualizer service..."
docker service create \
	--with-registry-auth \
	--name=viz \
	--port mode=ingress,target=8080,published=${VISUALIZER_PORT},protocol=tcp \
        --constraint=node.role==manager \
        --label kind=viz \
        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
        manomarks/visualizer

# Waiting for viz service to be running
wait_service "kind=viz" 1

VISUALIZER_IP=$(dm ip ${FIRST_MANAGER})
loghighlight "Visualizer is accessible on : http://${VISUALIZER_IP}:${VISUALIZER_PORT}"
echo ""
echo "Whale done ! :-)"
echo ""

loghighlight "========================================================"
