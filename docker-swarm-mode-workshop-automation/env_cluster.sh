#!/bin/bash

echo "Loading cluster configuration..."

# Cluster simple inventory as list to automate machines creation
# The first node of the managers list will be taken as the main manager for cluster initialisation 
export MANAGERS_LIST=( m1 m2 m3 )
export FIRST_MANAGER=${MANAGERS_LIST[0]}
export WORKERS_LIST=( w1 )

# Specific virtualization provider config
# (see cloud providers documentation for details)

# VirtualBox machines
export MANAGER_DRIVER_OPTS="-d virtualbox --virtualbox-memory=512"
export WORKER_DRIVER_OPTS="-d virtualbox --virtualbox-memory=512"

# For GCE machines, comment the 2 lines above and uncomment the following lines
# The use of "GOOGLE_USE_INTERNAL_IP" will make docker-machine use internal rather than public NATed IPs. 
# The flag is persistent in the sense that a machine created with it retains the IP. 
# It's useful for managing docker machines from another machine on the same network e.g. while deploying swarm.

# export MANAGER_DRIVER_OPTS="-d google"
# export WORKER_DRIVER_OPTS="-d google"
# export GOOGLE_PROJECT="oceirt-1191"
# export GOOGLE_ZONE="europe-west1-c"
# export GOOGLE_MACHINE_TYPE="n1-standard-2"
# export GOOGLE_TAGS="http-server,https-server"
# export GOOGLE_USE_INTERNAL_IP="true"


# worpress config
export WORDPRESS_NETWORK_NAME="wordpressnet"
export WORDPRESS_SERVICE_NAME="wordpress"
export WORDPRESS_DOCKER_IMAGE="wordpress:latest"
export WORDPRESS_SERVICE_PUBLISHED_PORT="80"

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

