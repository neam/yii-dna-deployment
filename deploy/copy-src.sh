#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

echo 'Copying source contents for '$APPVHOST' deployment...'

# current package path
script_path="$(dirname $0)"

function prepare_src_image_contents_for_service_in_stack {

    local SERVICE=$1

    if [ ! -f .stack.$SERVICE.filter.rules ]; then
      >&2 echo "Error: Missing rsync filter rules file for the stack's $SERVICE-service (.stack.$SERVICE.filter.rules)";
      exit 1;
    fi

    echo "* Copying build-artifacts to src-images-build/$SERVICE"
    time rsync -v --archive --one-file-system --progress --delete-excluded --filter="merge .stack.$SERVICE.filter.rules" ./ src-images-build/$SERVICE/

}

prepare_src_image_contents_for_service_in_stack php
prepare_src_image_contents_for_service_in_stack nginx
