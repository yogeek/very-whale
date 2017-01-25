#!/bin/bash

# Load cluster configuration
source env_cluster.sh $1

loghighlight "===================== STARTING VIZ ====================="

FIRST_MANAGER_IP="$(dm ip ${FIRST_MANAGER})"

# Start a cluster visualizer container to display the swarm deployment in a web page
# Can be started on any node of the cluster
loghighlight "Creating visualizer service..."
gcloud docker -- service create \
	--with-registry-auth \
	--name=viz \
	--publish ${VISUALIZER_PORT}:8080 \
        --constraint=node.role==manager \
        --label kind=viz \
        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
        manomarks/visualizer

# Waiting for viz service to be running
wait_service "kind=viz" 1


#docker run -it -d \
#	--name swarm_visualizer \
#	-p 8000:8080 \
#	-e HOST=localhost \
#	-v /var/run/docker.sock:/var/run/docker.sock \ 
#	manomarks/visualizer:beta

VISUALIZER_IP=$(dm ip ${FIRST_MANAGER})
loghighlight "Visualizer is accessible on : http://${VISUALIZER_IP}:${VISUALIZER_PORT}"
echo ""
echo "Whale done ! :-)"
echo ""

loghighlight "========================================================"
