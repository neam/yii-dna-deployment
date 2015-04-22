Yii DNA Deployment
==================

Deploying Yii DNA 12-factor-apps via Tutum.

Requires a compatible docker stack. Currently, the `debian-php-nginx.dna-project-base` stack available in [https://github.com/neam/docker-stack](https://github.com/neam/docker-stack) is recommended. Other docker-compose based stacks can be rather easily adapted to work with the below workflow. 

## Installation
 
1. Copy boilerplate files


    cp -r vendor/neam/yii-dna-deployment/skeleton/* . 
  
2. Create a private secrets.php file for sensitive deployment-related information that should not be committed


    cp deploy/config/secrets.dist.php deploy/config/secrets.php
    
3. Adapt `deploy/config/secrets.php` and `deploy/config/identity.php` for your project

## Deploy to Tutum cluster

To build and deploy on Tutum, first make sure that the required config vars are set properly in `deploy/config/secrets.php`.

Set the data profile to deploy:

    export DATA=clean-db # or any other data profile

Optionally set and/or change these options based on the desired deployment type (default values shown below):

    export BRANCH_TO_DEPLOY=$(git symbolic-ref --short -q HEAD)
    export GRANULARITY=project-branch-specific # alternatively: project-branch-commit-specific

Prepare the common variables (both locally and on build server):

    source vendor/neam/yii-dna-deployment/deploy/prepare.sh

Locally or on build server (not all commands are necessary on each incremental build, but are included for completeness):

    stack/src/git-pull-recursive.sh
    source vendor/neam/yii-dna-deployment/deploy/prepare.sh
    docker-compose pull
    stack/src/install-deps.sh
    vendor/bin/docker-stack build-directory-sync
    cd ../$(basename $(pwd))-build/
    stack/src/set-writable-local.sh
    docker-compose up -d
    docker-compose run builder stack/src/reset-vendor.sh
    docker-compose run -e PREFER=dist builder stack/src/install-deps.sh
    docker-compose run builder stack/src/build.sh
    stack/db-start.sh
    # first, set DATA in .env
    stack/shell.sh # and then bin/reset-db.sh --force-s3-sync   and bin/upload-current-media-as-public-files.sh
    docker-stack local url
    # <-- generate assets here
    # build
    vendor/neam/yii-dna-deployment/deploy/build.sh
    cd -

Locally:

    vendor/neam/yii-dna-deployment/deploy/set-config.sh

Follow given instructions and run generated commands to deploy to Tutum cluster.

At this stage the stack is prepared and runs the yii application, but if this is the first deployment, the database is completely empty. Reset the database to get a fully working deployment. Instructions are found below.

### Make publicly available

Link the router service to the new stack's `web` service and redeploy the router service.
TODO: Find a way to perform this efficiently with zero downtime.

## Interact with deployment
 
To SSH into the worker (replace `changeme` with the name of your stack that you want to interact with.):

    export STACK_NAME=changeme
    source deployments/$STACK_NAME/.env
    source deploy/prepare.sh
    vendor/neam/yii-dna-deployment/util/tutum-ssh.sh
    
This will print out commands for preparing you worker container.

Log in, follow the instructions and you should be able to perform any of the below tasks.

### Reset the database
 
Reset the database:

    vendor/neam/yii-dna-pre-release-testing/shell-scripts/reset-db.sh

### Upload current media files to s3 public files bucket

Upload current media files to s3 public files bucket:

    vendor/neam/yii-dna-deployment/util/upload-current-media-as-public-files.sh
