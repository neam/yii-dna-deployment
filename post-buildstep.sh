#!/bin/bash

set -x

if [ "$connectionID" == "" ]; then
    connectionID=db
fi

# fail on any error
set -o errexit

# necessary for user data backup uploads
deploy/install-s3cmd.sh

# install software useful to be contained in the docker image for debugging etc later
apt-get install -y -q sudo nano htop strace

# make sure that app/data/p3media is a symlink to persistent /cache/p3media already in the build
if [ -d app/data/p3media ] ; then
    mv app/data/p3media app/data/.p3media-directory-before-symlinking
fi
if [ ! -d /cache/p3media ] ; then
    mkdir /cache/p3media
    chown -R nobody: /cache/p3media
fi
if [ ! -L app/data/p3media ] ; then
    ln -s /cache/p3media app/data/p3media
fi

exit 0