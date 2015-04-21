#!/usr/bin/env bash

export DEPLOYMENT_DIR="$DEPLOYMENTS_ROOT/$APPVHOST/$COMMITSHA"
cd "$DEPLOYMENT_DIR"

STACK_ID=$(cat .tutum-stack-id)
tutum stack inspect $STACK_ID > .tutum-stack.json
WORKER_CONTAINER_ID=$(cat .tutum-stack.json | jq '.services | map(select(.name == "worker"))' | jq -r '.[0].containers[0]' | awk -F  "/" '{print $5}')
tutum container inspect $WORKER_CONTAINER_ID > .tutum-worker-container.json
SSH_PORT=$(cat .tutum-worker-container.json | jq '.container_ports[0].outer_port')
SSH_FQDN=$(cat .tutum-worker-container.json | jq -r '.link_variables.WORKER_ENV_TUTUM_NODE_FQDN')

echo "Init and connect:"
echo "export SSH_PORT=$SSH_PORT"
echo "export SSH_FQDN=$SSH_FQDN"
echo 'scp -r -P $SSH_PORT '$DEPLOYMENT_DIR'/.env root@$SSH_FQDN:/.env'
echo 'scp -r -P $SSH_PORT ~/.ssh/id_rsa root@$SSH_FQDN:/root/.ssh/id_rsa'
echo 'ssh -p $SSH_PORT root@$SSH_FQDN'
echo
echo "When connected:"
echo "apt-get update && apt-get install -y -q git-core"
echo "git clone --recursive \$PROJECT_GIT_REPO /app"
echo "cd /app"
echo "cp /.env .env"
echo "git checkout "$COMMITSHA
echo "PREFER=dist stack/src/install-deps.sh"
echo "source /.env"
echo
echo "Then run commands"

exit 0