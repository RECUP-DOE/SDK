#!/bin/bash

# Make dir to put everything in
mkdir -p wfmeta_darshan
cd wfmeta_darshan

# Get docker_compose file
COMMIT="652bae41f3c124e535bcd512801a294548667bdf"

wget -O docker-compose.yml https://raw.githubusercontent.com/infispiel/wfmeta-darshan/${COMMIT}/share/docker/prod/docker-compose_interactive.yml
docker compose -f docker-compose.yml run Interactive