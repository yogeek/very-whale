#!/bin/bash

docker service rm spark-worker
docker service rm spark-master
docker network rm sparknet
