#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

function build_and_push_src_image_for_service_in_stack {

    local SERVICE=$1

    docker build -f .stack.$SERVICE.Dockerfile -t $DOCKERCLOUD_USER/$REPO-$SERVICE:git-commit-$COMMITSHA .
    docker push $DOCKERCLOUD_USER/$REPO-$SERVICE:git-commit-$COMMITSHA

}

# build and push src to docker-cloud

set -x

build_and_push_src_image_for_service_in_stack php
build_and_push_src_image_for_service_in_stack nginx

set +x

# display deployment instructions

echo 'If no errors are shown above, docker images are prepared for '$APPVHOST' deployment'
