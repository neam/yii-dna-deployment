#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

# build and push src to docker-cloud

set -x
docker build -f .stack.php.Dockerfile -t $DOCKERCLOUD_USER/$REPO-php:git-commit-$COMMITSHA .
docker build -f .stack.nginx.Dockerfile -t $DOCKERCLOUD_USER/$REPO-nginx:git-commit-$COMMITSHA .
docker push $DOCKERCLOUD_USER/$REPO-php:git-commit-$COMMITSHA
docker push $DOCKERCLOUD_USER/$REPO-nginx:git-commit-$COMMITSHA
set +x

# display deployment instructions

echo 'If no errors are shown above, docker images are prepared for '$APPVHOST' deployment'
