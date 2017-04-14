#!/bin/bash

docker network create -d overlay --attachable docker_elk 

docker run \
		--network docker_elk \
		-p 9200:9200 -p 9300:9300 \
		-e ES_JAVA_OPTS="-Xms1g -Xmx1g" \
		-e xpack.security.enabled="false" \
		-e xpack.monitoring.enabled="false" \
		-e xpack.graph.enabled="false" \
		-e xpack.watcher.enabled="false" \
		dockerelk_elasticsearch