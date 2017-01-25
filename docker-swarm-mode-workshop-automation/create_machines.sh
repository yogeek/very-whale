#!/bin/bash

# Load cluster configuration
source env_cluster.sh $1

loghighlight "==================== MACHINES CREATION ====================="

# Create Managers machines
loghighlight "Creating managers..."
for manager in ${MANAGERS_LIST[*]}; do
    dm create $MANAGER_DRIVER_OPTS  $manager
    # Update Docker to RC version manually
#    dm scp rc-docker.sh $manager:~/
#    dm ssh $manager "~/rc-docker.sh"
done

# Create Workers machines
loghighlight "Creating workers..."
for worker in ${WORKERS_LIST[*]}; do
    dm create $WORKER_DRIVER_OPTS $worker
    # Update Docker to RC version manually
#    dm scp rc-docker.sh $worker:~/
#    dm ssh $worker "~/rc-docker.sh"
done

# Check machines
echo ""
loghighlight "---------- Machines list :"
dm ls
echo ""

loghighlight "============================================================"
