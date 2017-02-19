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

source env_cluster.sh $@

source create_machines.sh $@

source init_swarm.sh $@

#source pull_images.sh $1

source start_viz.sh $@

source deploy_wordpress.sh $@

