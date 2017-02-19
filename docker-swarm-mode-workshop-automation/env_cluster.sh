#!/bin/bash

#set -u

# Some useful functions
. ./utils.sh

function usage()
{
    echo ""
    echo "Usage : source env_cluster.sh -p <cloud_provider> -r <private_registry> "
    echo ""
    echo "Load environment config"
    echo ""
    echo "options :"
    echo -e "  -h, --help\t\t Print usage"
    echo -e "  -p, --provider string\t Docker Machine Driver to create instances ('virtualbox', 'google')"
    echo -e "  -r, --registry string\t Optional private registry ('local', '<REGISTRY_IP>:<REGISTRY_PORT>') (default = DockerHub)"
    echo ""
}

export LOCAL_REGISTRY_MACHINE="private-registry"
export LOCAL_REGISTRY_PORT="5000"

# Parse args
if [[ $# -eq 0 ]]
then 
    usage 
    return 1
fi 

while [[ $# -ge 1 ]]
do
    key="$1"

    case $key in
        -h|--help)
            usage
            return 0
            ;;
        -p|--provider)
            PROVIDER="$2"
            shift # past argument
            ;;
        -r|--registry)
            export REGISTRY_ARG="$2"
            shift # past argument
            ;;
        *) 
            logerror "Unknown option !"
            usage 
            return 1 
            ;; 
    esac
    shift # past argument or value
done

echo "Loading cluster configuration..."

# If a private registry is specified
if [[ ! -z $REGISTRY_ARG ]]  
then 
    # if 'local' is specified, start the local private resgistry
    if [[ "$REGISTRY_ARG" == "local" ]]
    then
        # Start Private Registry 
        loghighlight "Starting private registry docker machine..." 
        docker-machine start private-registry 
        # Check local private registry (stored in 'private-registry' docker machine) 
        export REGISTRY="$(dm ip $LOCAL_REGISTRY_MACHINE):${LOCAL_REGISTRY_PORT}" 
        if [[ $? -ne 0 ]] 
        then 
            loghighlight "Warning : you have to start 'private-registry' docker machine first !" 
            loghighlight "To do that : 'docker-machine start private-registry'" 
            return 0 
        fi 
        #REGISTRY_OPTS="--engine-insecure-registry ${REGISTRY}"
    fi
    export REGISTRY_PREFIX="${REGISTRY}/"
fi

echo "" 
echo "Images will be pulled from : ${REGISTRY:-'Docker Hub'}"
echo ""

# Cluster simple inventory as list to automate machines creation
# The first node of the managers list will be taken as the main manager for cluster initialisation 
export MANAGERS_LIST=( m1 )
export FIRST_MANAGER=${MANAGERS_LIST[0]}
export WORKERS_LIST=( w1 w2 w3)

# Specific virtualization provider config
# (see cloud providers documentation for details)

case "$PROVIDER" in
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
            echo ""
            loghighlight "You launch this script from a machine outside of your GCE project. "
            loghighlight "Please set PROJECT_ID variable to <your_google_project_id>."
            echo ""
            return 0
        fi
    fi

    # URL of the Docker Engine version to be installed on the Docker Machines
    # If not specified, the package version is taken
    #export ENGINE_URL=""
    # Test version
    #export ENGINE_URL="--engine-install-url https://test.docker.com/"
    
    # Options for "docker-machine create" command for manager nodes
    export MANAGER_DRIVER_OPTS="-d google ${ENGINE_URL:-}"
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
    export GOOGLE_TAGS="http-server,https-server,spark-on-swarm"

    # The use of "GOOGLE_USE_INTERNAL_IP" will make docker-machine use internal rather than public NATed IPs. 
    # The flag is persistent in the sense that a machine created with it retains the IP. 
    # It's useful for managing docker machines from another machine on the same network e.g. while deploying swarm.
    # --google-use-internal-ip
    export GOOGLE_USE_INTERNAL_IP="true"
    
    #--google-scopes storage-rw,cloud-platform,service-control,service-management"
    #SCOPE_PREFIX_URL="https://www.googleapis.com/auth/"
    #export GOOGLE_SCOPES="${SCOPE_PREFIX_URL}devstorage.read_write,\
    #                      ${SCOPE_PREFIX_URL}cloud-platform,\
    #                      ${SCOPE_PREFIX_URL}servicecontrol,\
    #                      ${SCOPE_PREFIX_URL}service.management"
    ;;
  *)
    logerror "Error ! Invalid argument."
    usage
    ;;
esac

# Network config
export WORDPRESS_NETWORK_NAME="wordpressnet"

# worpress config
export WORDPRESS_SERVICE_NAME="wordpress"
export WORDPRESS_DOCKER_IMAGE="${REGISTRY_PREFIX:-}wordpress:latest"
export WORDPRESS_SERVICE_PUBLISHED_PORT="80"

export WORDPRESS_SERVICE_REPLICAS=3

# mysql config
export MYSQL_SERVICE_NAME="wordpressdb"
export MYSQL_DOCKER_IMAGE="${REGISTRY_PREFIX:-}mysql:latest"
export MYSQL_DATABASE="wordpress"
export MYSQL_ROOT_PASSWORD="password"

# Visualizer
export VISUALIZER_IMAGE="${REGISTRY_PREFIX:-}manomarks/visualizer:latest"
export VISUALIZER_PORT="8080"

export ENV_OK="true"

trace () {
    echo ""
    echo "-----------------------------------------------------"
    echo "PROVIDER = $PROVIDER"
    echo "WORDPRESS_DOCKER_IMAGE = $WORDPRESS_DOCKER_IMAGE"
    echo "MYSQL_DOCKER_IMAGE = $MYSQL_DOCKER_IMAGE"
    echo "VISUALIZER_IMAGE =$VISUALIZER_IMAGE"
    echo "-----------------------------------------------------"
}