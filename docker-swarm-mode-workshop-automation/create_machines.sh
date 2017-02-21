#!/bin/bash

source env_cluster.sh "$@"

function copy_registry_crt() {
	loghighlight "********* Copying Registry certs to the machine..."
	rm -rf ./registry_certs
	mkdir ./registry_certs
	# Get certificate from registry machine
	dm scp private-registry:/home/docker/certs/* ./registry_certs/
	# Copy them to current machine
	dm scp -r registry_certs/domain.crt $1:~docker/
	dm ssh $1 'sudo mkdir -p /etc/docker/certs.d/192.168.99.100\:5000/'
	dm ssh $1 'sudo cp ~docker/domain.crt /etc/docker/certs.d/192.168.99.100\:5000/ca.crt'
	dm ssh $1 'sudo cp ~docker/domain.crt /usr/local/share/ca-certificates/192.168.99.100.crt'
}

loghighlight "==================== MACHINES CREATION ====================="

# Create Managers machines
loghighlight "Creating managers nodes..."
for manager in ${MANAGERS_LIST[*]}; do
    dm create $MANAGER_DRIVER_OPTS $REGISTRY_OPTS $manager
    if [[ "$REGISTRY_ARG" == "local" ]]
    then 
    	copy_registry_crt $manager
    fi
done

# Create Workers machines
loghighlight "Creating workers nodes..."
for worker in ${WORKERS_LIST[*]}; do
    dm create $WORKER_DRIVER_OPTS $REGISTRY_OPTS $worker
    if [[ "$REGISTRY_ARG" == "local" ]]
    then 
    	copy_registry_crt $worker
    fi
done

# Check machines
echo ""
loghighlight "---------- Machines list :"
dm ls
echo ""

loghighlight "============================================================"
