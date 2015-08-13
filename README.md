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

    brew install tutum

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
    export COMMITSHA=
    source vendor/neam/yii-dna-deployment/deploy/prepare.sh
    docker-compose pull
    stack/src/install-deps.sh
    vendor/bin/docker-stack build-directory-sync
    cd ../$(basename $(pwd))-build/
    stack/src/set-writable-local.sh
    docker-compose rm -f
    docker-compose up -d
    docker-compose run builder stack/src/reset-vendor.sh # do not forget to compile assets if resetting vendor completely
    docker-compose run -e PREFER=dist builder stack/src/install-deps.sh
    docker-compose run builder /project/$(basename $(pwd))/stack/src/build.sh # takes 1-2 minutes

Set up a temporary deployment on the build server:
    
    docker-compose rm --force
    docker-compose up -d
    echo "DATA=$DATA" >> .env
    stack/db-start.sh
    docker-stack local run worker /bin/bash bin/reset-db.sh --force-s3-sync
    stack/src/set-writable-local.sh

Upload the media files to cdn:

    docker-stack local run worker /bin/bash bin/upload-current-files-to-cdn.sh

Now we need to test the build and generated backend assets (done automatically by visiting the backend):

    docker-stack local url

Now, generate assets that are not versioned but need to be part of the deployed image.

Then build and push the source code to tutum:
    
    vendor/neam/yii-dna-deployment/deploy/build.sh
    cd -
    
The commands required for an incremental update (ie the build directory already exists from an earlier deployment):

    stack/src/git-pull-recursive.sh
    export COMMITSHA=
    source vendor/neam/yii-dna-deployment/deploy/prepare.sh
    vendor/bin/docker-stack build-directory-sync
    cd ../$(basename $(pwd))-build/
    docker-compose run -e PREFER=dist builder stack/src/install-deps.sh
    docker-compose run builder /project/$(basename $(pwd))/stack/src/build.sh
    vendor/neam/yii-dna-deployment/deploy/build.sh

Locally:

    vendor/neam/yii-dna-deployment/deploy/generate-config.sh

Follow given instructions and run generated commands to deploy to Tutum cluster.

At this stage the stack is prepared and runs the yii application, but if this is the first deployment, the database is completely empty. Reset the database to get a fully working deployment. Instructions are found below.

### Make publicly available

Link the router service to the new stack's `web` service and redeploy the router service.
TODO: Find a way to perform this efficiently with zero downtime.

## Running worker commands in an already deployed stack

List available stacks:

    tutum stack list

To access a shell in the running stack's containers (replace `changeme` with the name of your stack that you want to interact with):

    export STACK_NAME=changeme
    export DATA=changeme
    source vendor/neam/yii-dna-deployment/deploy/prepare.sh
    vendor/neam/yii-dna-deployment/util/tutum-shell.sh $STACK_NAME

Then, when connected:

    cd /app
    source .env

Now, you can run commands inside the container (examples below).

### Reset the database
 
Reset the database:

    vendor/neam/yii-dna-pre-release-testing/shell-scripts/reset-db.sh

### Upload current media files to s3 public files bucket

Upload current media files to s3 public files bucket:

    vendor/neam/yii-dna-deployment/util/upload-current-media-as-public-files.sh
