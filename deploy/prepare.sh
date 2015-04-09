# no shebang since this file is included through the source command/macro

# This script should be sourced when pwd is the main project repo root

    pwd="$(pwd)"
    export BUILD_DIR="$pwd"
    #echo "pwd=$pwd"

    if [ "$BRANCH_TO_DEPLOY" == "" ]; then
        export BRANCH_TO_DEPLOY=$(git symbolic-ref --short -q HEAD)
    fi

    export DEFAULT_COVERAGE="$COVERAGE"
    export DRONE_BRANCH="$BRANCH_TO_DEPLOY"
    export DRONE_BUILD_DIR="$BUILD_DIR/.."
    export COMMITSHA=$(git rev-parse --verify --short=7 HEAD)
    export DEPLOYMENTS_ROOT=deployments
    export APPVHOST="" # always reset this, let it be set from set-deployment-target.inc.sh below

    export CONFIG_INCLUDE=vendor/neam/yii-dna-deployment/deploy/prepare.php
    php vendor/neam/php-app-config/export.php > /tmp/php-app-config.sh

    if [ "$?" == "0" ]; then

        source /tmp/php-app-config.sh
        source $DRONE_BUILD_DIR/set-deployment-target.inc.sh
        export APPNAME=$WEB_APPNAME
        export APPVHOST=$WEB_HOST

        # show exported variables
        echo
        echo "This branch will be deployed to http://$APPVHOST"
        echo

        echo "export BRANCH_TO_DEPLOY=$BRANCH_TO_DEPLOY"
        echo "export DATA=$DATA"
        echo "export GRANULARITY=$GRANULARITY"
        #echo "export COVERAGE=$COVERAGE"

        echo
        echo "Note: If you adjust the above environment variables you need to re-run the prepare script, since the subdomain to deploy to and the below variables may change."
        echo

        echo "export APPVHOST=$APPVHOST"
        echo "export APPNAME=$APPNAME"
        echo "export DEPLOY_STABILITY_TAG=$DEPLOY_STABILITY_TAG"
        echo "export DOCKER_REGISTRY_USER=$DOCKER_REGISTRY_USER"
        echo "export TUTUM_USER=$TUTUM_USER"
        echo "export TOPLEVEL_DOMAIN=$TOPLEVEL_DOMAIN"
        echo "export COMMITSHA=$COMMITSHA"
        echo

    else

        # show error messages
        cat /tmp/php-app-config.sh

    fi

    cd $pwd
