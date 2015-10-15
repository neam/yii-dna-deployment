Yii DNA Deployment
==================

Deploying Yii DNA 12-factor-apps via Tutum.

Requires a compatible docker stack. Currently, the `debian-php-nginx.dna-project-base` stack available in [https://github.com/neam/docker-stack](https://github.com/neam/docker-stack) is recommended. Other docker-compose based stacks can be rather easily adapted to work with the below workflow. 

## Installation
 
1. Copy boilerplate files


    cp -r vendor/neam/yii-dna-deployment/skeleton/* . 
  
2. Create a private configuration files for sensitive deployment-related information that should not be committed


    cp deploy/config/deploy-prepare-secrets.dist.php deploy/config/deploy-prepare-secrets.php
    cp deploy/config/secrets.dist.php deploy/config/secrets.php

3. Adapt `deploy/config/deploy-prepare-secrets.dist.php`, `deploy/config/secrets.php` and `deploy/config/identity.php` for your project

## Documentation

It is recommended to build and push the docker images on a shell server. Set one up and make sure it has access to relevant source code repositories. If you prefer, you can use your own workstation as a build server. In that case, simply open up a new terminal window locally and run the below build server commands locally instead.

TODO: Include documentation adapted from [DNA Project Base](neamlabs.com/dna-project-base/) here.
