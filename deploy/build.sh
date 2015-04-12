#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

# build and push src to tutum

set -x
docker build -f .stack.php.Dockerfile -t $DOCKER_REGISTRY_USER/$REPO-php:git-commit-$COMMITSHA .
docker build -f .stack.nginx.Dockerfile -t $DOCKER_REGISTRY_USER/$REPO-nginx:git-commit-$COMMITSHA .
docker tag -f $DOCKER_REGISTRY_USER/$REPO-php:git-commit-$COMMITSHA tutum.co/$TUTUM_USER/$REPO-nginx:git-commit-$COMMITSHA
docker tag -f $DOCKER_REGISTRY_USER/$REPO-nginx:git-commit-$COMMITSHA tutum.co/$TUTUM_USER/$REPO-php:git-commit-$COMMITSHA
docker login --email=$TUTUM_EMAIL --username=$TUTUM_USER --password=$TUTUM_PASSWORD https://tutum.co/v1
docker push tutum.co/$TUTUM_USER/$REPO-php:git-commit-$COMMITSHA
docker push tutum.co/$TUTUM_USER/$REPO-nginx:git-commit-$COMMITSHA
set +x

# display deployment instructions

echo 'If no errors are shown above, docker images are prepared for '$APPVHOST' deployment'
