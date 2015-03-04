#!/bin/bash

# only run in dokku deployments
if [ ! "${ENV:0:5}" == "dokku" ]; then
    exit 0
fi

# make sure that persistent /cache/p3media exists
if [ ! -d /cache/p3media ] ; then
    mkdir /cache/p3media
fi

# set permissions for persistent /cache/p3media
chown -R www-data:www-data /cache/p3media
chmod -R g+rw /cache/p3media
# temporarily
chmod -R 777 /cache/p3media

exit 0
