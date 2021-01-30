#!/bin/bash -e

if [ -z "$1" ]; then
  echo "Must specify docker image as first argument"
fi

DOCKER_IMAGE=$1

echo "Provisioning docker image $DOCKER_IMAGE"

# cleanup previous deployment
docker stop quotes || true
docker rm quotes || true

eval $(aws ecr get-login --region us-east-1 --no-include-email)

docker pull $DOCKER_IMAGE

docker run -d \
  --name quotes \
  --restart always \
  -p 8082:8082 \
  $DOCKER_IMAGE
