#!/bin/bash
set -euxo pipefail

dnf install -y docker
systemctl enable --now docker

docker pull ${container_image}

docker rm -f tsp 2>/dev/null || true
docker run -d \
  --name tsp \
  --restart unless-stopped \
  -p ${host_port}:${container_port} \
  -e NODE_ENV=production \
  -e PORT=${container_port} \
  ${container_image}
