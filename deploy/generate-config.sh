#!/bin/bash

# Script to generate config for the 12-factor-app's tutum stack

# debug

#set -x

# script path
script_path=$(dirname $0)

# Show script name and line number when errors occur to make errors easier to debug
trap 'echo "Script error in $0 on or near line ${LINENO}"' ERR

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

# create directory for deployment config

DATETIME=$(date +"%Y-%m-%d_%H%M%S")
export STACK_NAME=$(servicename "$DATETIME-$APPVHOST-$COMMITSHA")
export DEPLOYMENT_DIR="$DEPLOYMENTS_ROOT/$STACK_NAME"
mkdir -p "$DEPLOYMENT_DIR"

# export the current app config (making sure that the required config vars are set properly (tip: use your local secrets.php file to supply sensitive configuration values when deploying from locally)

export CONFIG_INCLUDE=vendor/neam/yii-dna-deployment/deploy/generate-config.php

echo
echo 'Config for '$APPVHOST':'
echo

# we ignore runtime-config which are set on the fly
php vendor/neam/php-app-config/export.php | grep -v 'export DATABASE_USER=' | grep -v 'export DATA=' | grep -v 'export DATABASE_NAME=' > $DEPLOYMENT_DIR/.env

if [ "$?" == "0" ]; then
    source $DEPLOYMENT_DIR/.env

    # prepare stack yml

    cat stack/docker-compose-production.yml \
     | sed 's|%COMMITSHA%|'$COMMITSHA'|' \
     | sed 's|%ENV_FILE_DIR%|.|' \
     | sed 's|%APPVHOST%|'$APPVHOST'|' \
     | sed 's|%DEPLOY_STABILITY_TAG%|'$DEPLOY_STABILITY_TAG'|' \
     | sed 's|%TUTUM_USER%|'$TUTUM_USER'|' \
     | sed 's|%REPO%|'$REPO'|' \
     | sed 's|%VIRTUAL_HOST%|'$APPVHOST'|' \
     > $DEPLOYMENT_DIR/docker-compose-production.yml

    cat $DEPLOYMENT_DIR/.env \
     | grep -v '=""' \
     | sed 's|export |    |' \
     | sed 's|="|: "|' \
     | sed 's|\\\?|\?|' \
     > $DEPLOYMENT_DIR/.env.yml

    VIRTUAL_HOST_BASED_WEB_SERVICE_NAME=$(servicename "web${APPVHOST}${COMMITSHA}")

    cat stack/docker-compose-production-tutum.yml \
     | sed 's|%COMMITSHA%|'$COMMITSHA'|' \
     | sed 's|%APPVHOST%|'$APPVHOST'|' \
     | sed 's|%DEPLOY_STABILITY_TAG%|'$DEPLOY_STABILITY_TAG'|' \
     | sed 's|%TUTUM_USER%|'$TUTUM_USER'|' \
     | sed 's|%REPO%|'$REPO'|' \
     | sed 's|%VIRTUAL_HOST%|'$APPVHOST'|' \
     | sed 's|%VIRTUAL_HOST_BASED_WEB_SERVICE_NAME%|'$VIRTUAL_HOST_BASED_WEB_SERVICE_NAME'|' \
     > $DEPLOYMENT_DIR/docker-compose-production-tutum.yml

    sed -e '/ENVIRONMENT_YAML/ {' -e 'r '"$DEPLOYMENT_DIR/.env.yml" -e 'd' -e '}' -i '' $DEPLOYMENT_DIR/docker-compose-production-tutum.yml

fi

cat $DEPLOYMENT_DIR/.env
echo

# prepare new db

if [ "$DATABASE_HOST" == "" ]; then
    $script_path/../util/prepare-new-db.sh $APPVHOST
fi

echo
echo 'If no errors are shown above, config is prepared for '$APPVHOST'. To build images and push to tutum registry:'
echo
echo "  vendor/neam/yii-dna-deployment/deploy/build.sh"
echo
echo "Make sure these tutum credentials are used"
echo
echo "  export TUTUM_USER=\$TUTUM_USER"
echo "  export TUTUM_APIKEY=\$TUTUM_APIKEY"
echo
echo 'Then, run one of the following to deploy:'
echo
echo "  tutum stack create --name=$STACK_NAME -f $DEPLOYMENT_DIR/docker-compose-production-tutum.yml | tee $DEPLOYMENT_DIR/.tutum-stack-id && \\"
echo "  tutum stack start \$(cat $DEPLOYMENT_DIR/.tutum-stack-id)"
echo
echo "  tutum stack update -f $DEPLOYMENT_DIR/docker-compose-production-tutum.yml \$(cat $DEPLOYMENT_DIR/.tutum-stack-id)"
echo "  tutum stack redeploy \$(cat $DEPLOYMENT_DIR/.tutum-stack-id)"
echo
echo "  docker-compose --project-name $APPVHOST -f $DEPLOYMENT_DIR/docker-compose-production.yml up -d"
echo
