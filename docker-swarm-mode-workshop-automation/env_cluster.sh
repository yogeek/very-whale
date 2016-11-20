#!/bin/bash

echo "Loading cluster configuration..."

# Cluster simple inventory as list to automate machines creation
# The first node of the managers list will be taken as the main manager for cluster initialisation 
export MANAGERS_LIST=( m1 m2 m3 )
export FIRST_MANAGER=${MANAGERS_LIST[0]}
export WORKERS_LIST=( w1 )

# worpress config
export WORDPRESS_NETWORK_NAME="wordpressnet"
export WORDPRESS_SERVICE_NAME="wordpress"
export WORDPRESS_DOCKER_IMAGE="wordpress:latest"
export WORDPRESS_SERVICE_PUBLISHED_PORT=80

export WORDPRESS_SERVICE_REPLICAS=3

# mysql config
export MYSQL_SERVICE_NAME="wordpressdb"
export MYSQL_DOCKER_IMAGE="mysql:latest"
export MYSQL_DATABASE="wordpress"
export MYSQL_ROOT_PASSWORD="password"

# Visualizer
export VISUALIZER_IMAGE="manomarks/visualizer"
export VISUALIZER_PORT="8080"

# Highlighting message
loghighlight () {
	RESTORE='\033[0m'
	LGREEN='\033[01;32m'
	echo -e "${LGREEN}$@${RESTORE}"
}

echo "Loading docker-machine wrapper..."

# Use the docker-machine wrapper function from docker-machine wrapper script
# (https://docs.docker.com/machine/install-machine/#/installing-bash-completion-scripts)
__docker_machine_wrapper () {
    if [[ "$1" == use ]]; then
        # Special use wrapper
        shift 1
        case "$1" in
            -h|--help|"")
                cat <<EOF
Usage: docker-machine use [OPTIONS] [arg...]

Evaluate the commands to set up the environment for the Docker client

Description:
   Argument is a machine name.

Options:

   --swarm	Display the Swarm config instead of the Docker daemon
   --unset, -u	Unset variables instead of setting them

EOF
                ;;
            *)
                eval "$(docker-machine env "$@")"
                echo "Active machine: ${DOCKER_MACHINE_NAME}"
                . ~/.bashrc
                ;;
        esac
    else
        # Just call the actual docker-machine app
        command docker-machine "$@"
    fi
}

# Shortcut for docker-machine wrapper command
dm () {
	__docker_machine_wrapper "$@" 
}
