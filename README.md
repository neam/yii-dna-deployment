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

On build server:

    docker-compose pull
    docker-compose run builder stack/src/git-pull-recursive.sh
    docker-compose run builder stack/src/reset-vendor.sh
    docker-compose run builder /bin/bash manager/ui/angular-frontend/full-build.sh
    vendor/neam/yii-dna-deployment/deploy/build.sh

Locally:

    vendor/neam/yii-dna-deployment/deploy/set-config.sh

Follow given instructions and run generated commands to deploy to Tutum cluster.

At this stage the stack is prepared and runs the yii application, but if this is the first deployment, the database is completely empty. Reset the database to get a fully working deployment. Instructions are found below.

### Make publicly available

Link the router service to the new stack's `web` service and redeploy the router service.
TODO: Find a way to perform this efficiently with zero downtime.

### Reset the database
 
SSH into the worker:

    $(vendor/neam/yii-dna-deployment/util/tutum-ssh.sh)
    
Copy paste the contents of deployments/{relevant-deployment}/.env into the SSH session.

Reset the database:

    /app/bin/reset-db.sh
 