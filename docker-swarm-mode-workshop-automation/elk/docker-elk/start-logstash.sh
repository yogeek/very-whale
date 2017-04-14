docker run \
		--network docker_elk \
		-p 5000:5000 \
		-v $(pwd)/docker-elk/logstash/pipeline:/usr/share/logstash/pipeline \
		dockerelk_logstash