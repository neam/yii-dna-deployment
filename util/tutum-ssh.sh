#!/usr/bin/env bash

cd $DEPLOYMENTS_ROOT/$APPVHOST

STACK_ID=$(cat .tutum-stack-id)
tutum stack inspect $STACK_ID > .tutum-stack.json
WORKER_CONTAINER_ID=$(cat .tutum-stack.json | jq '.services | map(select(.name == "worker"))' | jq -r '.[0].containers[0]' | awk -F  "/" '{print $5}')
tutum container inspect $WORKER_CONTAINER_ID > .tutum-worker-container.json
SSH_PORT=$(cat .tutum-worker-container.json | jq '.container_ports[0].outer_port')
SSH_FQDN=$(cat .tutum-worker-container.json | jq -r '.link_variables.WORKER_ENV_TUTUM_NODE_FQDN')

echo "ssh -p $SSH_PORT root@$SSH_FQDN"

exit 0