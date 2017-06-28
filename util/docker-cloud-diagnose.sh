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
echo "# To launch a clone of the stack (in order to then terminate/replace the original stack):"
DATETIME=$(date +"%Y%m%d%H%M%S")
echo "  cp $DEPLOYMENT_DIR/.docker-cloud-stack-id $DEPLOYMENT_DIR/.docker-cloud-stack-id.bak.$DATETIME"
echo "  docker-cloud stack create --name=${STACK_NAME}clone${DATETIME} -f $DEPLOYMENT_DIR/docker-compose-production-docker-cloud.yml | tee $DEPLOYMENT_DIR/.docker-cloud-stack-id && \\"
echo "  docker-cloud stack start \$(cat $DEPLOYMENT_DIR/.docker-cloud-stack-id)"
echo
echo "# To deploy a new stack with the same source code:"
echo "  export DATA=$DATA"
echo "  export COMMITSHA=$COMMITSHA"
echo "  export BRANCH_TO_DEPLOY=$BRANCH_TO_DEPLOY"
echo "  source deploy/prepare.sh"
echo "  deploy/generate-config.sh"

STACK_ID=$(cat .docker-cloud-stack-id)
docker-cloud stack inspect $STACK_ID > .docker-cloud-stack.json

if [ "$(cat .docker-cloud-stack.json | jq -r '.state')" == "Terminated" ]; then
    echo "Stack is terminated";
    exit 0;
fi

echo
echo "# The stack's non-public containers:"
docker-cloud container ps | grep $STACK_NAME | tee .docker-cloud-containers

echo
echo "# To open a shell into the stack's non-public containers:"
cat .docker-cloud-containers | grep -v Terminated | awk '{ print "docker-cloud exec " $2 " /bin/bash # (" $1 ")"  }'

# Commented since broken
#echo
#echo "# The stack's non-public containers are running on the following nodes:"
#set -x
#cat .docker-cloud-stack.json | jq '.services' | grep _ENV_DOCKERCLOUD_NODE_FQDN | grep -v '"key"' | grep '_\d_' | sed 's/^/{/' | sed 's/,/}/' | jq -s add | tee .docker-cloud-containers-nodes
#echo
#echo "# To ssh into the docker-cloud nodes and run further diagnostics:"
#cat .docker-cloud-containers-nodes | jq -r '.[]' | sort -u | sed 's/^/ssh root@/'
#echo
#echo "# Or, using mosh"
#cat .docker-cloud-containers-nodes | jq -r '.[]' | sort -u | sed 's/^/mosh root@/'

WEB_CONTAINER_ID=$(cat .docker-cloud-containers | grep -v Terminated | grep ^web | awk '{ print $2  }')
docker-cloud container inspect $WEB_CONTAINER_ID > .docker-cloud-web-container.json
PHPHAPROXY_CONTAINER_ID=$(cat .docker-cloud-containers | grep -v Terminated | grep ^phphaproxy | awk '{ print $2  }')
docker-cloud container inspect $PHPHAPROXY_CONTAINER_ID > .docker-cloud-phphaproxy-container.json

WEB_PORT=$(cat .docker-cloud-web-container.json | jq '.container_ports  | map(select(.inner_port == 80)) | .[].outer_port')
WEB_FQDN=$(cat .docker-cloud-web-container.json | jq '.link_variables' | grep '"WEB.*_ENV_DOCKERCLOUD_NODE_FQDN' | sed 's/^/{/' | sed 's/,/}/' | grep -v '_\d_' | jq -r '.[]')
export INNER_STATS_PORT=8088 # use 1936 later
PHPHAPROXY_STATS_PORT=$(cat .docker-cloud-phphaproxy-container.json | jq '.container_ports  | map(select(.inner_port == '$INNER_STATS_PORT')) | .[].outer_port')
PHPHAPROXY_STATS_FQDN=$(cat .docker-cloud-phphaproxy-container.json | jq '.link_variables' | grep '"PHPHAPROXY.*_ENV_DOCKERCLOUD_NODE_FQDN' | sed 's/^/{/' | sed 's/,/}/' | grep -v '_\d_' | jq -r '.[]')
PHPHAPROXY_STATS_AUTH=$(cat .docker-cloud-phphaproxy-container.json | jq '.link_variables' | grep '"PHPHAPROXY.*_ENV_STATS_AUTH' | sed 's/^/{/' | sed 's/,//' | sed 's/$/}/' | grep -v '_\d_' | jq -r '.[]')

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
echo 'open http://$PHPHAPROXY_STATS_AUTH@$PHPHAPROXY_STATS_FQDN:$PHPHAPROXY_STATS_PORT'
echo
exit 0
