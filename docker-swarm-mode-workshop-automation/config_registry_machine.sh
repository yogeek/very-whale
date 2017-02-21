#/bin/bash

LOCAL_REGISTRY_CONF=/home/guillaume/docker-private-registry/registry_certs

REGISTRY_MACHINE="private-registry"
REGISTRY_PORT="5000"

IP=$(docker-machine ip $REGISTRY_MACHINE)

# Copy openssl.cnf 
docker-machine scp ${LOCAL_REGISTRY_CONF}/openssl.cnf ${REGISTRY_MACHINE}:openssl.cnf
docker-machine ssh ${REGISTRY_MACHINE} 'sudo mv openssl.cnf /etc/ssl/openssl.cnf'

# Copy certs
docker-machine ssh ${REGISTRY_MACHINE} 'sudo rm -rf ~/certs'
docker-machine scp -r ${LOCAL_REGISTRY_CONF}/certs/ ${REGISTRY_MACHINE}:~
docker-machine ssh ${REGISTRY_MACHINE} 'sudo mkdir -p /etc/docker/certs.d/'"${IP}"':5000'
docker-machine ssh ${REGISTRY_MACHINE} 'sudo cp ~/certs/domain.crt /etc/docker/certs.d/'"${IP}"'\:5000/ca.crt'

# Copy auth
docker-machine ssh ${REGISTRY_MACHINE} 'sudo rm -rf ~/auth'
docker-machine scp -r ${LOCAL_REGISTRY_CONF}/auth/ ${REGISTRY_MACHINE}:~

# Start Registry
docker-machine ssh ${REGISTRY_MACHINE} 'docker rm -f registry'
docker-machine ssh ${REGISTRY_MACHINE} 'docker run -d -p 5000:5000 \
	--restart=always \
	--name registry \
	-v /home/docker/auth:/auth \
	-v /home/docker/certs:/certs \
	-v registry_volume:/var/lib/registry \
	-e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
	-e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
	-e "REGISTRY_AUTH=htpasswd" \
	-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
	-e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
	registry:2'

echo "Local Registry Securely Configured !"