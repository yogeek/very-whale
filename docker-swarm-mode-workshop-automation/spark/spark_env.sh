#!/bin/bash

set -u

if [[ $# -ne 1 ]]
then
    echo "Usage : spark-env.sh <cloud_driver>"
    echo "with :"
    echo "  <cloud_driver>  = Docker Machine Driver to create instances"
    echo "                    Choices : virtualbox, google"
    echo ""
    exit 1
fi

echo "Loading cluster configuration..."

# Cluster simple inventory as list to automate machines creation
# The first node of the managers list will be taken as the main manager for cluster initialisation 
export MANAGERS_LIST=( m1 m2 m3 )
export FIRST_MANAGER=${MANAGERS_LIST[0]}
export WORKERS_LIST=( w1 )

# Specific virtualization provider config
# (see cloud providers documentation for details)

case "$1" in
  # VirtualBox machines
  "virtualbox")
    echo "Driver = VIRTUALBOX"
    MACHINE_DRIVER="virtualbox"
    export MANAGER_DRIVER_OPTS="-d virtualbox --virtualbox-memory=512"
    export WORKER_DRIVER_OPTS="-d virtualbox --virtualbox-memory=512"
    ;;
  # GCE machines
  "google")
    echo "Driver = GOOGLE"
    MACHINE_DRIVER="google"
    
    if [[ -z ${PROJECT_ID} || "${PROJECT_ID}" == "" ]]
    then
        # Get current project ID programmatically if we launch this script on a GCE host
        PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id)
        if [[ -z ${PROJECT_ID} || "${PROJECT_ID}" == "" ]]
        then
            echo "Please set PROJECT_ID variable to <your_google_project_id>."
            return
        fi
    fi
    
    # URL of the Docker Engine version to be installed on the Docker Machines
    # If not specified, the package version is taken
    #export ENGINE_URL=""
    # Test version (to use v1.13-rc2 needed for swarm mode service discovery through specific overlay network)
    export ENGINE_URL="--engine-install-url https://test.docker.com/"
    
    # Options for "docker-machine create" command for manager nodes
    export MANAGER_DRIVER_OPTS="-d google $ENGINE_URL"
    # Options for "docker-machine create" command for worker nodes
    export WORKER_DRIVER_OPTS="$MANAGER_DRIVER_OPTS"

    # --google-project ${PROJECT_ID}
    export GOOGLE_PROJECT=${PROJECT_ID:-}

    # --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20161205
    export GOOGLE_MACHINE_IMAGE="https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20161205"
    
    # --google-zone europe-west1-c
    export GOOGLE_ZONE="europe-west1-c"
    
    # --google-machine-type n1-standard-2
    export GOOGLE_MACHINE_TYPE="n1-standard-2"
    
    # --tags https-server,http-server
    export GOOGLE_TAGS="http-server,https-server"

    # The use of "GOOGLE_USE_INTERNAL_IP" will make docker-machine use internal rather than public NATed IPs. 
    # The flag is persistent in the sense that a machine created with it retains the IP. 
    # It's useful for managing docker machines from another machine on the same network e.g. while deploying swarm.
    # --google-use-internal-ip
    export GOOGLE_USE_INTERNAL_IP="true"
    
    #--google-scopes storage-rw,cloud-platform,service-control,service-management"
    SCOPE_PREFIX_URL="https://www.googleapis.com/auth/"
    export GOOGLE_SCOPES="${SCOPE_PREFIX_URL}devstorage.read_write,${SCOPE_PREFIX_URL}cloud-platform,${SCOPE_PREFIX_URL}servicecontrol,${SCOPE_PREFIX_URL}service.management"
    ;;
  *)
    echo "Error ! Invalid argument."
    echo "You must specify a machine driver among : virtualbox, google" 
    return
    ;;
esac

# Network config
export SPARK_NETWORK_NAME="sparknet"

# master config
export SPARK_MASTER_SERVICE_NAME="spark-master"
export SPARK_MASTER_DOCKER_IMAGE="gcr.io/"$PROJECT_ID"/python-base-spark"
export SPARK_MASTER_SERVICE_PUBLISHED_PORT="8080"
export SPARK_MASTER_SERVICE_REPLICAS=1

# worker config
export SPARK_WORKER_SERVICE_NAME="spark-worker"
export SPARK_WORKER_DOCKER_IMAGE="gcr.io/"$PROJECT_ID"/python-base-spark"
export SPARK_WORKER_SERVICE_REPLICAS=3

# Visualizer
export VISUALIZER_IMAGE="manomarks/visualizer"
export VISUALIZER_PORT="80"

# Highlighting message
loghighlight () {
    echo ""
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

# Function to wait for a service to be ready
# Usage : wait_service <label_key:label_value> <desired_replicas>
wait_service () {
	SERVICE_LABEL=$1
	SERVICE_REPLICAS=${2:-"1"}
	while [[ ! $(docker service ls -f label=${SERVICE_LABEL} | grep -v REPLICAS | grep "${SERVICE_REPLICAS}/${SERVICE_REPLICAS}") ]]; do
        	echo "waiting for ${SERVICE_REPLICAS} replicas of service labelled '${SERVICE_LABEL}' to be ready..."
	        sleep 10
	done
	echo "Service is ready !"
	echo ""
}
