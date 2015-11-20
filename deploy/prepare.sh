# no shebang since this file is included through the source command/macro

# This script should be sourced when pwd is the main project repo root

    pwd="$(pwd)"
    export BUILD_DIR="$pwd"
    #echo "pwd=$pwd"

    # default to multi-tenant deployment
    if [ "$DATA" == "" ]; then
        export DATA='%DATA%'
    fi

    # default to current branch
    if [ "$BRANCH_TO_DEPLOY" == "" ]; then
        export BRANCH_TO_DEPLOY=$(git symbolic-ref --short -q HEAD)
    fi

    # default to current git repo
    if [ "$PROJECT_GIT_REPO" == "" ]; then
        export PROJECT_GIT_REPO=$(git config --get remote.origin.url)
    fi

    # default to current commitsha
    if [ "$COMMITSHA" == "" ]; then
        export COMMITSHA=$(git rev-parse --verify --short=7 HEAD)
    fi

    export DEFAULT_COVERAGE="$COVERAGE"
    export DRONE_BRANCH="$BRANCH_TO_DEPLOY"
    export DRONE_BUILD_DIR="$BUILD_DIR/.."
    export DEPLOYMENTS_ROOT=deployments
    export APPVHOST="" # always reset this, let it be set from set-deployment-target.inc.sh below

    export CONFIG_INCLUDE=vendor/neam/yii-dna-deployment/deploy/prepare.php
    php vendor/neam/php-app-config/export.php > /tmp/php-app-config.sh

    if [ "$?" == "0" ]; then

        source /tmp/php-app-config.sh
        source $BUILD_DIR/set-deployment-target.inc.sh

        # show exported variables
        $BUILD_DIR/vendor/neam/yii-dna-deployment/deploy/show-prepared.sh

    else

        # show error messages
        cat /tmp/php-app-config.sh

    fi

    cd $pwd
