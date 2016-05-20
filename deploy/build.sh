#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

# current package path
script_path="$(dirname $0)"

# docker-diff-based-layers is assumed to be installed in the same directory as yii-dna-deployment
DOCKER_DIFF_BASED_LAYERS_PACKAGE_PATH="$script_path/../../docker-diff-based-layers"

if [ "$DOCKERCLOUD_USER" == "" ]; then
  echo "Error: Missing information about which docker-cloud user owns the repository to push to (DOCKERCLOUD_USER)";
  exit 1;
fi

if [ "$REPO" == "" ]; then
  echo "Error: Missing information about which repository to push to (REPO)";
  exit 1;
fi

if [ "$COMMITSHA" == "" ]; then
  echo "Error: Missing information about which commit sha this src image refers to (COMMITSHA)";
  exit 1;
fi

function build_src_image_for_service_in_stack {

    local __returnvar=$1
    local SERVICE=$2

    if [ ! -f .stack.$SERVICE.Dockerfile ]; then
      >&2 echo "Error: Missing Dockerfile for the stack's $SERVICE-service (.stack.$SERVICE.Dockerfile)";
      exit 1;
    fi

    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    # tags specific to the new src image
    local LARGE_LAYER_TAG="git-commit-$COMMITSHA.large-layer.not-pushed"

    local TAG_TO_PUSH="git-commit-$COMMITSHA"
    eval $__returnvar="'$TAG_TO_PUSH'"

    #1. build an ordinary src image
    time docker build -f .stack.$SERVICE.Dockerfile -t $IMAGE_REPO:$LARGE_LAYER_TAG .

    # Verify that subsequent `COPY . /app` commands re-adds all files in every layer instead of only the files that have changed.
    docker history $IMAGE_REPO:$LARGE_LAYER_TAG | head -n 5
    # Even though we added/changed only a few bytes, all files are re-added and 16.78 MB is added to the total image size.

    docker tag $IMAGE_REPO:$LARGE_LAYER_TAG $IMAGE_REPO:$TAG_TO_PUSH


}

function push_src_image_for_service_in_stack {

    local SERVICE=$1
    local TAG_TO_PUSH=$2
    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    docker push $IMAGE_REPO:$TAG_TO_PUSH
    echo "$TAG_TO_PUSH" > .stack.$SERVICE.previously-pushed-tag

}

# build and push src to docker-cloud

build_src_image_for_service_in_stack TAG_TO_PUSH_PHP php
build_src_image_for_service_in_stack TAG_TO_PUSH_NGINX nginx

push_src_image_for_service_in_stack php $TAG_TO_PUSH_PHP
push_src_image_for_service_in_stack nginx $TAG_TO_PUSH_NGINX

# display deployment instructions

echo 'If no errors are shown above, docker images are prepared for '$APPVHOST' deployment'
