#!/bin/bash -e

if [ -z "$1" ]; then
  echo "Must specify docker image as first argument"
fi

DOCKER_IMAGE=$1

echo "Provisioning docker image $DOCKER_IMAGE"

# cleanup previous deployment
docker stop newsfeed || true
docker rm newsfeed || true

eval $(aws ecr get-login --region eu-west-1 --no-include-email)

docker pull $DOCKER_IMAGE

docker run -d \
  --name newsfeed \
  --restart always \
  -p 8081:8081 \
  $DOCKER_IMAGE
