#!/bin/bash

# Make dir to put everything in
mkdir -p wfmeta_darshan
cd wfmeta_darshan

mkdir output

# Get docker_compose file

wget -O docker-compose.yml https://raw.githubusercontent.com/infispiel/wfmeta-darshan/refs/heads/main/share/docker/prod/docker-compose_interactive.yml
docker compose -f docker-compose.yml run Interactive wfmeta_darshan -d /resource/Data/ImageProcessing/D2024-04-18_15:54:02_R1_W8 /resource/host/output