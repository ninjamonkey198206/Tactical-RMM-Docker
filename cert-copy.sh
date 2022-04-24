#!/usr/bin/env bash


# Edit to match T-RMM docker-compose.yml path, including trailing /
# Example: /var/lib/docker/tactical-rmm/
DOCKER_COMPOSE_DIR='0'

# Edit to match correct T-RMM tactical_data volume path for certs, including trailing /
# Example: /var/lib/docker/volumes/tacticalrmm_tactical_data/_data/certs/
TRMM_CERT_DIR='0'

# Edit to match LetsEncrypt cert/key path, including trailing /
# Example: /etc/letsencrypt/live/example.com/
LE_CERT_PATH='0'


sudo cp ${LE_CERT_PATH}fullchain.pem ${TRMM_CERT_DIR}fullchain.pem && sudo cp ${LE_CERT_PATH}privkey.pem ${TRMM_CERT_DIR}privkey.pem

sudo docker-compose -f ${DOCKER_COMPOSE_DIR}docker-compose.yml down && sudo docker-compose -f ${DOCKER_COMPOSE_DIR}docker-compose.yml up -d
