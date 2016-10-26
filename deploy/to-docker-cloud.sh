#!/usr/bin/env bash

# fail on any error
set -o errexit

# debug
#set -x

DEPLOYMENT_DIR="$1"
STACK_NAME="$(basename $DEPLOYMENT_DIR)"

echo "Deploying to docker-cloud (using the currently set Docker Cloud user 'DOCKERCLOUD_USER=$DOCKERCLOUD_USER')"
echo "* Creating the stack"
id=$(docker run -d -e DOCKERCLOUD_USER=$DOCKERCLOUD_USER -e DOCKERCLOUD_PASS=$DOCKERCLOUD_PASS -v "$(pwd)/$DEPLOYMENT_DIR:/deployment-dir" dockercloud/cli stack create --name=$STACK_NAME -f /deployment-dir/docker-compose-production.docker-cloud.yml)
test "$(docker wait "$id")" -eq 0 || (docker logs "$id" && exit 1)
UUID=$(docker logs "$id")
echo $UUID | tee $DEPLOYMENT_DIR/.docker-cloud-stack-id
echo "* Starting the stack"
id=$(docker run -d -e DOCKERCLOUD_USER=$DOCKERCLOUD_USER -e DOCKERCLOUD_PASS=$DOCKERCLOUD_PASS -v "$(pwd)/$DEPLOYMENT_DIR:/deployment-dir" dockercloud/cli stack start $UUID)
test "$(docker wait "$id")" -eq 0 || (docker logs "$id" && exit 1)
echo "* Listing current stacks"
docker run -it -e DOCKERCLOUD_USER=$DOCKERCLOUD_USER -e DOCKERCLOUD_PASS=$DOCKERCLOUD_PASS -v "$(pwd)/$DEPLOYMENT_DIR:/deployment-dir" --rm dockercloud/cli stack ls

exit 0
