#!/bin/bash

source env_cluster.sh "$@"

loghighlight "====================== PULLING IMAGES ======================"

# Pull images on all nodes 
loghighlight "--------- Pulling docker images on nodes..."
for node in ${MANAGERS_LIST[@]}; do
        dm ssh $node "sudo gcloud docker pull ${SPARK_MASTER_DOCKER_IMAGE}"
done
for node in ${WORKERS_LIST[@]}; do
        dm ssh $node "sudo gcloud docker pull ${SPARK_WORKER_DOCKER_IMAGE}"
done

loghighlight "============================================================"