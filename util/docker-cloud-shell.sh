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

STACK_ID=$(cat .docker-cloud-stack-id)
docker-cloud stack inspect $STACK_ID > .docker-cloud-stack.json
WORKER_CONTAINER_ID=$(cat .docker-cloud-stack.json | jq '.services | map(select(.name == "worker"))' | jq -r '.[0].containers[0]' | awk -F  "/" '{print $5}')
# docker-cloud container inspect $WORKER_CONTAINER_ID > .docker-cloud-worker-container.json

docker-cloud exec $WORKER_CONTAINER_ID

exit 0

echo "Init and connect:"
echo "export SSH_PORT=$SSH_PORT"
echo "export SSH_FQDN=$SSH_FQDN"
echo 'scp -r -P $SSH_PORT '$DEPLOYMENT_DIR'/.env root@$SSH_FQDN:/.env'
echo 'scp -r -P $SSH_PORT .files/'$DATA'/media/* root@$SSH_FQDN:/files/'$DATA'/media/'
echo
echo "Use local ssh keys:"
echo "echo 'Host $SSH_FQDN' >> ~/.ssh/config"
echo "echo '	ForwardAgent yes' >> ~/.ssh/config"
echo
echo "Connect:"
echo 'ssh -p $SSH_PORT root@$SSH_FQDN'
echo
echo "When connected:"
echo "source /.env"
echo
echo "# File permissions"
echo "chown -R \$WEB_SERVER_POSIX_USER:\$WEB_SERVER_POSIX_GROUP /files"
echo
echo "# Be able to run commands like reset-db etc"
echo "git clone --recursive \$PROJECT_GIT_REPO /app"
echo "cd /app"
echo "cp /.env .env"
echo "git checkout "$COMMITSHA
echo "PREFER=dist stack/src/install-deps.sh"
echo "PREFER=source stack/src/install-deps.sh"
echo
echo "Then run commands"

exit 0