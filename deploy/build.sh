#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

echo 'Preparing docker images for '$APPVHOST' deployment...'

# current package path
script_path="$(dirname $0)"

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

if [ "$1" == "--skip-build" ]; then
  SKIP_BUILD=1
fi

if [ "$1" == "--skip-push" ]; then
  SKIP_PUSH=1
fi

function tag_for_service_in_stack {

    local __returnvar=$1

    local TAG_TO_PUSH="git-commit-$COMMITSHA"
    eval $__returnvar="'$TAG_TO_PUSH'"

}

function build_src_image_for_service_in_stack {

    local TAG_TO_PUSH=$1
    local SERVICE=$2

    cd src-images-build/$SERVICE

    if [ ! -f .stack.$SERVICE.Dockerfile ]; then
      >&2 echo "Error: Missing Dockerfile for the stack's $SERVICE-service (.stack.$SERVICE.Dockerfile)";
      exit 1;
    fi

    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    # tags specific to the new src image
    local LARGE_LAYER_TAG="git-commit-$COMMITSHA.large-layer.not-pushed"

    echo "* Running build_src_image_for_service_in_stack for $SERVICE as $IMAGE_REPO:$TAG_TO_PUSH"

    #1. build an ordinary src image
    time docker build -f .stack.$SERVICE.Dockerfile -t $IMAGE_REPO:$LARGE_LAYER_TAG .

    cd -

    # Verify that subsequent `COPY . /app` commands re-adds all files in every layer instead of only the files that have changed.
    docker history $IMAGE_REPO:$LARGE_LAYER_TAG | head -n 5
    # Even though we added/changed only a few bytes, all files are re-added and 16.78 MB is added to the total image size.

    docker tag $IMAGE_REPO:$LARGE_LAYER_TAG $IMAGE_REPO:$TAG_TO_PUSH

}

function echo_push_src_image_for_service_in_stack {

    local SERVICE=$1
    local TAG_TO_PUSH=$2
    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    echo "# To push $SERVICE, tag $TAG_TO_PUSH:"

    echo docker push $IMAGE_REPO:$TAG_TO_PUSH

}

function push_src_image_for_service_in_stack {

    local SERVICE=$1
    local TAG_TO_PUSH=$2
    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    echo "* Running push_src_image_for_service_in_stack for $SERVICE, pushing tag $TAG_TO_PUSH"

    docker push $IMAGE_REPO:$TAG_TO_PUSH

}

# build and push src to docker-cloud

tag_for_service_in_stack TAG_TO_PUSH_PHP
tag_for_service_in_stack TAG_TO_PUSH_NGINX

if [ ! "$SKIP_BUILD" == "1" ]; then
  vendor/neam/yii-dna-deployment/deploy/copy-src.sh
  build_src_image_for_service_in_stack $TAG_TO_PUSH_PHP php
  build_src_image_for_service_in_stack $TAG_TO_PUSH_NGINX nginx
  echo
  echo 'Docker images are built for '$APPVHOST' deployment.'
fi

if [ "$SKIP_PUSH" == "1" ]; then
  echo_push_src_image_for_service_in_stack php $TAG_TO_PUSH_PHP
  echo_push_src_image_for_service_in_stack nginx $TAG_TO_PUSH_NGINX
else
  docker login --username $DOCKERCLOUD_USER --password $DOCKERCLOUD_PASS
  push_src_image_for_service_in_stack php $TAG_TO_PUSH_PHP
  push_src_image_for_service_in_stack nginx $TAG_TO_PUSH_NGINX
  echo
  echo 'Docker images are pushed for '$APPVHOST' deployment.'
fi
