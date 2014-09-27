#!/bin/bash

# This file performs certain actions in the end of the buildpack build process,
# thus changes here are compiled into the application slug.
# The working directory is $BUILD_DIR

# debug
set -x

# fail on any error
set -o errexit

# necessary for user data backup uploads
vendor/neam/yii-dna-deployment/install-s3cmd.sh

# install software useful to be contained in the docker image for debugging etc later
apt-get install -y -q sudo nano htop strace

# set relative data path
data_path=dna/db/data

# make sure that app/data/p3media is a symlink to persistent /cache/p3media already in the build
if [ -d $data_path/p3media ] ; then
    mv $data_path/p3media $data_path/.p3media-directory-before-symlinking
fi
if [ ! -d /cache/p3media ] ; then
    mkdir /cache/p3media
    chown -R nobody: /cache/p3media
    chmod -R g+rw /cache/p3media
fi
if [ ! -L $data_path/p3media ] ; then
    ln -s /cache/p3media $data_path/p3media
fi

exit 0