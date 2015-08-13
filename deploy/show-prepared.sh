#!/usr/bin/env bash

# show prepared variables
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

echo "Necessary for generate-config:"
echo "export APPVHOST=$APPVHOST"
echo "export APPNAME=$APPNAME"
echo "export DEPLOY_STABILITY_TAG=$DEPLOY_STABILITY_TAG"
echo "export TOPLEVEL_DOMAIN=$TOPLEVEL_DOMAIN"
echo
echo "Necessary for build and push:"
echo "export DOCKER_REGISTRY_USER=$DOCKER_REGISTRY_USER"
echo "export TUTUM_USER=$TUTUM_USER"
echo "export COMMITSHA=$COMMITSHA"
echo
