docker run \
		--network docker_elk \
		-p 5601:5601 \
		-v $(pwd)/docker-elk/kibana/config/:/usr/share/kibana/config \
		dockerelk_kibana