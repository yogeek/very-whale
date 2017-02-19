# Automation of Docker 1.12 Swarm-Mode workshop :whale:

## Description

Simple scripts using docker-machine and Docker swarm-mode to automate the creation of a swarm cluster
and the deployment of a wordpress stack on it.
The wordpress stack is composed of a wordpress service (with N replicas) and a mysql service (with only one replica).
A [Docker Swarm Visualizer](https://github.com/ManoMarks/docker-swarm-visualizer) service is also deployed to have a graphical view of the cluster. 

__Update__ : now available the new "docker stack deploy" feature !

## Prerequisites

Before you start, make sure you have :

* [Docker 1.13+](https://docs.docker.com/engine/installation/) installed,
* [Docker Machine 1.11+](https://docs.docker.com/machine/install-machine/) installed

 ## How to use

### Configure a cluster

Edit the `env_cluster.sh` file to configure the cluster.
     
### Create a cluster

```
source ./wordpress-on-swarm.sh -p virtualbox
```

The wordpress app will be accessible at : http://\<ANY_SWARM_NODE_IP\>:${WORDPRESS_SERVICE_PUBLISHED_PORT}

The swarm vizualiser will be accessible at : http://\<ANY_SWARM_NODE_IP\>:${VISUALIZER_PORT} and will display a dynamic view of the swarm :

![swarm-viz](resources/docker-swarm-mode-viz.png)

### Deploy a stack

You can also use the latest Docker 1.13 stack deployment with Docker Compose 1.11+ :
```
	docker stack deploy -c docker-compose.yaml wordpress_stack
```

### Play with the cluster

* Scale the wordpress service to 10 replicas
```
docker service scale wordpress=10
```

* Stop one of the containers of wordpress service and check that swarm-mode starts another replicas to maintain the descriptive state.

* Delete a manager node and check that swarm-mode elects a new leader and that services containers that were on this node are started on another node. 

* and many others things to test !

### Delete cluster

```
source ./delete-cluster.sh
```

