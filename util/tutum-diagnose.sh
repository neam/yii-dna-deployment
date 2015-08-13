#!/usr/bin/env bash
#set -x

# fail on any error
set -o errexit

# Usage: deploy.sh <stackname>

if [ "$DEPLOYMENTS_ROOT" == "" ]; then
    DEPLOYMENTS_ROOT=deployments
fi

if [ "$1" == "" ]; then

  function servicename {

      local STR=$1

      # Permitted characters: [0-9,a-z,A-Z] (basic Latin letters, digits 0-9)
      STR=${STR//\//}
      STR=${STR//./}
      STR=${STR//-/}
      STR=${STR//_/}
      STR="$(echo $STR | tr '[:upper:]' '[:lower:]')" # UPPERCASE to lowercase
      # Max length 64 chars
      STR=${STR:0:64}

      echo "$STR"

  }

  # choose the latest stack
  export STACK_NAME=$(ls $DEPLOYMENTS_ROOT/ | grep $(servicename "-$APPVHOST-$COMMITSHA") | tail -n 1)
  if [ "$STACK_NAME" == "" ]; then
    echo "No stack found at $DEPLOYMENTS_ROOT/"$(servicename "-$APPVHOST-$COMMITSHA")"/"
    exit 1
  fi

else
  if [ -d "$DEPLOYMENTS_ROOT/$1" ]; then
    export STACK_NAME=$1
  fi
  if [ -d "$1" ]; then
    export STACK_NAME=$(basename $1)
  fi
fi

export DEPLOYMENT_DIR="$DEPLOYMENTS_ROOT/$STACK_NAME"
cd "$DEPLOYMENT_DIR"

source .env

echo
echo "# To replace the stack with a clone:"
DATETIME=$(date +"%Y%m%d%H%M%S")
echo "  cp $DEPLOYMENT_DIR/.tutum-stack-id $DEPLOYMENT_DIR/.tutum-stack-id.bak.$DATETIME"
echo "  tutum stack create --name=${STACK_NAME}clone{$DATETIME} -f $DEPLOYMENT_DIR/docker-compose-production-tutum.yml | tee $DEPLOYMENT_DIR/.tutum-stack-id && \\"
echo "  tutum stack start \$(cat $DEPLOYMENT_DIR/.tutum-stack-id)"
echo
echo "# To deploy a new stack with the same source code:"
echo "  export DATA=$DATA"
echo "  export COMMITSHA=$COMMITSHA"
echo "  export BRANCH_TO_DEPLOY=$BRANCH_TO_DEPLOY"
echo "  source deploy/prepare.sh"
echo "  deploy/generate-config.sh"

STACK_ID=$(cat .tutum-stack-id)
tutum stack inspect $STACK_ID > .tutum-stack.json

if [ "$(cat .tutum-stack.json | jq -r '.state')" == "Terminated" ]; then
    echo "Stack is terminated";
    exit 0;
fi

echo
echo "# The stack's non-public containers are running on the following nodes:"
cat .tutum-stack.json | jq '.services' | grep _ENV_TUTUM_NODE_FQDN | grep -v '"key"' | grep '_\d_' | sed 's/^/{/' | sed 's/,/}/' | jq -s add | tee .tutum-containers-nodes
echo
echo "# To ssh into the tutum nodes and run further diagnostics:"
cat .tutum-containers-nodes | jq -r '.[]' | sort -u | sed 's/^/ssh root@/'
echo
echo "# Or, using mosh"
cat .tutum-containers-nodes | jq -r '.[]' | sort -u | sed 's/^/mosh root@/'

WORKER_CONTAINER_ID=$(cat .tutum-stack.json | jq '.services | map(select(.name == "worker"))' | jq -r '.[0].containers[0]' | awk -F  "/" '{print $5}')
tutum container inspect $WORKER_CONTAINER_ID > .tutum-worker-container.json
WEB_CONTAINER_ID=$(cat .tutum-stack.json | jq '.services | map(select(.run_command == "/app/stack/nginx/run.sh"))' | jq -r '.[0].containers[0]' | awk -F  "/" '{print $5}')
tutum container inspect $WEB_CONTAINER_ID > .tutum-web-container.json
PHPHAPROXY_CONTAINER_ID=$(cat .tutum-stack.json | jq '.services | map(select(.name == "phphaproxy"))' | jq -r '.[0].containers[0]' | awk -F  "/" '{print $5}')
tutum container inspect $PHPHAPROXY_CONTAINER_ID > .tutum-phphaproxy-container.json

SSH_PORT=$(cat .tutum-worker-container.json | jq '.container_ports  | map(select(.inner_port == 22)) | .[].outer_port')
SSH_FQDN=$(cat .tutum-worker-container.json | jq -r '.link_variables.WORKER_ENV_TUTUM_NODE_FQDN')
WEB_PORT=$(cat .tutum-web-container.json | jq '.container_ports  | map(select(.inner_port == 80)) | .[].outer_port')
WEB_FQDN=$(cat .tutum-web-container.json | jq '.link_variables' | grep '"WEB.*_ENV_TUTUM_NODE_FQDN' | sed 's/^/{/' | sed 's/,/}/' | grep -v '_\d_' | jq -r '.[]')
PHPHAPROXY_STATS_PORT=$(cat .tutum-phphaproxy-container.json | jq '.container_ports  | map(select(.inner_port == 1936)) | .[].outer_port')
PHPHAPROXY_STATS_FQDN=$(cat .tutum-phphaproxy-container.json | jq '.link_variables' | grep '"PHPHAPROXY.*_ENV_TUTUM_NODE_FQDN' | sed 's/^/{/' | sed 's/,/}/' | grep -v '_\d_' | jq -r '.[]')
PHPHAPROXY_STATS_AUTH=$(cat .tutum-phphaproxy-container.json | jq '.link_variables' | grep '"PHPHAPROXY.*_ENV_STATS_AUTH' | sed 's/^/{/' | sed 's/,/}/' | grep -v '_\d_' | jq -r '.[]')

echo
echo "# Health-checks for public frontend:"
echo "export WEB_PORT=80"
echo "export WEB_FQDN=$APPVHOST"
echo "stack/_util/health-checks.sh"
echo
echo "# Health-checks for first-level backend (Nginx):"
echo "export WEB_PORT=$WEB_PORT"
echo "export WEB_FQDN=$WEB_FQDN"
echo "stack/_util/health-checks.sh"
echo
echo "# Stats for second-level backend (PHP haproxy):"
echo "export PHPHAPROXY_STATS_PORT=$PHPHAPROXY_STATS_PORT"
echo "export PHPHAPROXY_STATS_FQDN=$PHPHAPROXY_STATS_FQDN"
echo "export PHPHAPROXY_STATS_AUTH=$PHPHAPROXY_STATS_AUTH"
echo 'open http://$PHPHAPROXY_STATS_FQDN:$PHPHAPROXY_STATS_PORT'
echo
exit 0
