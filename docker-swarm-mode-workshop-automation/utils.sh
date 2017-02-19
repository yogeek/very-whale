#!/bin/bash

# Colors
RESTORE='\033[0m'
LGREEN='\033[01;32m'
RED='\033[0;31m'

# Highlighting message
function loghighlight () {
	echo -e "${LGREEN}$@${RESTORE}"
}

# Error message
function logerror () {
	echo -e "${RED}$@${RESTORE}"
}


# Function to wait for a service to be ready
# Usage : wait_service <label_key:label_value> <desired_replicas>
function wait_service () {
    SERVICE_LABEL=$1
    SERVICE_REPLICAS=${2:-"1"}
    while [[ ! $(docker service ls -f label=${SERVICE_LABEL} | grep -v REPLICAS | grep "${SERVICE_REPLICAS}/${SERVICE_REPLICAS}") ]]; do
            echo "waiting for ${SERVICE_REPLICAS} replicas of service labelled '${SERVICE_LABEL}' to be ready..."
            sleep 10
    done
    echo "Service is ready !"
    echo ""
}

# Check if cluster environment has been loaded
function check_env {
    echo "Checking environment..."
	if [[ "$ENV_OK" != "true" ]]
	then
		#logerror "You must load environment : 'source env_cluster.sh -h'"
		source env_cluster "$@"
        return 1
    else
        loghighlight "Environment already loaded."
	fi
}

# echo "Loading docker-machine wrapper..."

# # Use the docker-machine wrapper function from docker-machine wrapper script
# # (https://docs.docker.com/machine/install-machine/#/installing-bash-completion-scripts)
# __docker_machine_wrapper () {
#     if [[ "$1" == use ]]; then
#         # Special use wrapper
#         shift 1
#         case "$1" in
#             -h|--help|"")
#                 cat <<EOF
# Usage: docker-machine use [OPTIONS] [arg...]

# Evaluate the commands to set up the environment for the Docker client

# Description:
#    Argument is a machine name.

# Options:

#    --swarm	Display the Swarm config instead of the Docker daemon
#    --unset, -u	Unset variables instead of setting them

# EOF
#                 ;;
#             *)
#                 eval "$(docker-machine env "$@")"
#                 echo "Active machine: ${DOCKER_MACHINE_NAME}"
#                 . ~/.bashrc
#                 ;;
#         esac
#     else
#         # Just call the actual docker-machine app
#         command docker-machine "$@"
#     fi
# }

# # Shortcut for docker-machine wrapper command
# function dm () {
# 	__docker_machine_wrapper "$@" 
# }

