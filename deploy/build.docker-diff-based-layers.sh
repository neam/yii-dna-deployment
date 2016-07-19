#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

echo 'Preparing docker images for '$APPVHOST' deployment...'

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

# This function executes a build and push equivalent (and sometimes falling back to):
#    docker build -f .stack.$SERVICE.Dockerfile -t $IMAGE_REPO:git-commit-$COMMITSHA .
#    docker push $IMAGE_REPO:git-commit-$COMMITSHA
# An important optimization is in place: Rsync (via docker-diff-based-layers) is used in an attempt to produce a small differential
# layer with only the changes from a previously pushed image layer. If this succeeds, that layer is pushed instead, resulting in
# substantially less data to push and pull from the registries for developers, build-server-logic and production deployments.
# For instance, if the source code is 200mb large, a differential image layer may be only a few hundred kilobytes for small updates.
# Thus, instead of each agent pushing and pulling 200mb to get the patch, only the few hundred kilobytes are transferred.
function build_src_image_for_service_in_stack {

    local __returnvar=$1
    local SERVICE=$2

    cd src-images-build/$SERVICE

    if [ ! -f .stack.$SERVICE.Dockerfile ]; then
      >&2 echo "Error: Missing Dockerfile for the stack's $SERVICE-service (.stack.$SERVICE.Dockerfile)";
      exit 1;
    fi

    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    if [ ! -f .stack.$SERVICE.previously-pushed-tag ]; then
      echo "Notice: No file with the previously pushed tag found for the stack's $SERVICE-service (.stack.$SERVICE.previously-pushed-tag) - building an ordinary image and creating the mentioned file after a successful push. "
    fi
    local PREVIOUSLY_PUSHED_TAG="$(cat .stack.$SERVICE.previously-pushed-tag)"

    # tags specific to the new src image
    local PREVIOUSLY_PUSHED_BASE_LAYER_TAG="git-commit-$COMMITSHA.base-layer.previously-pushed"
    local LARGE_LAYER_TAG="git-commit-$COMMITSHA.large-layer.not-pushed"
    local DIFF_BASED_LAYER_TAG="git-commit-$COMMITSHA.diff-based-layer"

    local TAG_TO_PUSH="git-commit-$COMMITSHA"
    eval $__returnvar="'$TAG_TO_PUSH'"

    echo "* Running build_src_image_for_service_in_stack for $SERVICE as $IMAGE_REPO:$TAG_TO_PUSH"

    #1. build an ordinary src image
    time docker build -f .stack.$SERVICE.Dockerfile -t $IMAGE_REPO:$LARGE_LAYER_TAG .

    cd -

    # Verify that subsequent `COPY . /app` commands re-adds all files in every layer instead of only the files that have changed.
    docker history $IMAGE_REPO:$LARGE_LAYER_TAG | head -n 5
    # Even though we added/changed only a few bytes, all files are re-added and 16.78 MB is added to the total image size.

    if [ "$PREVIOUSLY_PUSHED_TAG" != "" ]; then

      #2. tag the previously pushed image/layer as $COMMITSHA.base-layer.already-pushed
      docker tag $IMAGE_REPO:$PREVIOUSLY_PUSHED_TAG $IMAGE_REPO:$PREVIOUSLY_PUSHED_BASE_LAYER_TAG

      #3. Create an image with an optimized layer

      export OLD_IMAGE=$IMAGE_REPO:$PREVIOUSLY_PUSHED_BASE_LAYER_TAG
      export NEW_IMAGE=$IMAGE_REPO:$LARGE_LAYER_TAG
      cd "$DOCKER_DIFF_BASED_LAYERS_PACKAGE_PATH"
      docker-compose -f rsync-image-diff.docker-compose.yml down
      docker-compose -f rsync-image-diff.docker-compose.yml rm -f
      docker-compose -f rsync-image-diff.docker-compose.yml up -d
      docker-compose -f rsync-image-diff.docker-compose.yml run --rm new_large_layer /.docker-image-diff/create-changelog-to-go-from-old-to-new.sh
      docker-compose -f rsync-image-diff.docker-compose.yml stop
      docker-compose -f shell.docker-compose.yml -f process-image-diff.docker-compose.yml run --rm shell ./generate-dockerfile.sh
      cd -
      cd "$DOCKER_DIFF_BASED_LAYERS_PACKAGE_PATH/output";
      docker build -t $IMAGE_REPO:$DIFF_BASED_LAYER_TAG .;
      cd -

      # Verify that the processed new image has smaller sized layers with the changes
      docker history $IMAGE_REPO:$DIFF_BASED_LAYER_TAG | head

      #4. Verify that the processed new image contains the same contents as the original

      export OLD_IMAGE=$IMAGE_REPO:$LARGE_LAYER_TAG
      export NEW_IMAGE=$IMAGE_REPO:$DIFF_BASED_LAYER_TAG
      cd "$DOCKER_DIFF_BASED_LAYERS_PACKAGE_PATH"
      docker-compose -f rsync-image-diff.docker-compose.yml up
      cd -

      #5. om de INTE är identiska, se till att pusha "vanliga" istället, och uppdatera infon kring previously pushed image/layer
      echo "TODO"
      exit 1;

      # make sure that the previously pushed tag is actually pushed
      docker push $IMAGE_REPO:$PREVIOUSLY_PUSHED_TAG

      # push the diff-based layer
      docker tag $IMAGE_REPO:$DIFF_BASED_LAYER_TAG $IMAGE_REPO:$TAG_TO_PUSH

    else

     docker tag $IMAGE_REPO:$LARGE_LAYER_TAG $IMAGE_REPO:$TAG_TO_PUSH

    fi

}

function echo_push_src_image_for_service_in_stack {

    local SERVICE=$1
    local TAG_TO_PUSH=$2
    local IMAGE_REPO="$DOCKERCLOUD_USER/$REPO-$SERVICE"

    echo "* Running push_src_image_for_service_in_stack for $SERVICE, pushing tag $TAG_TO_PUSH"

    echo docker push $IMAGE_REPO:$TAG_TO_PUSH
    echo echo "$TAG_TO_PUSH" \> .stack.$SERVICE.previously-pushed-tag

}

# build and push src to docker-cloud

build_src_image_for_service_in_stack TAG_TO_PUSH_PHP php
build_src_image_for_service_in_stack TAG_TO_PUSH_NGINX nginx

echo 'If no errors are shown above, docker images are built for '$APPVHOST' deployment. To push:'
echo
echo_push_src_image_for_service_in_stack php $TAG_TO_PUSH_PHP
echo_push_src_image_for_service_in_stack nginx $TAG_TO_PUSH_NGINX
echo