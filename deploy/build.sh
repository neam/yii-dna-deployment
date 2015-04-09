#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

# build and push src to tutum

set -x
docker build -f .src.builder.Dockerfile -t $DOCKER_REGISTRY_USER/$REPO:git-commit-$COMMITSHA .
docker tag -f $DOCKER_REGISTRY_USER/$REPO:git-commit-$COMMITSHA tutum.co/$TUTUM_USER/$REPO:git-commit-$COMMITSHA
docker login --email=$TUTUM_EMAIL --username=$TUTUM_USER --password=$TUTUM_PASSWORD https://tutum.co/v1
docker push tutum.co/$TUTUM_USER/$REPO:git-commit-$COMMITSHA
set +x

# display deployment instructions

echo 'If no errors are shown above, docker images are prepared for '$APPVHOST' deployment'
