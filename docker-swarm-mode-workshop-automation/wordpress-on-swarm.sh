#!/bin/bash

##############################################################################################
# This script aims to deploy Spark on a Docker swarm-mode cluster
#
# Prerequisites :
#       - docker 1.12 (https://docs.docker.com/engine/installation/)
#       - docker-machine 0.8.2 (https://docs.docker.com/machine/install-machine/)
#       - docker-machine "bash completion scripts" 
#         (https://docs.docker.com/machine/install-machine/#/installing-bash-completion-scripts)
#
# Configuration must be specified in "spark_env.sh".
#
##############################################################################################


if [[ $# -ne 1 ]]
then
    echo "Usage : wordpress-on-swarm.sh <cloud_driver>"
    echo "with :"
    echo "	<cloud_driver> 	= Docker Machine Driver to create instances"
    echo "					  Choices : virtualbox, google"
    echo ""
    exit 1
fi

source env_cluster.sh $1

source create_machines.sh $1

source init_swarm.sh $1

#source pull_images.sh $1

source deploy_wordpress.sh $1

source start_viz.sh $1

