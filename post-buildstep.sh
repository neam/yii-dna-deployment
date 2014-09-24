#!/bin/bash

set -x

if [ "$connectionID" == "" ]; then
    connectionID=db
fi
chown -R nobody: app/data/
chown -R nobody: app/runtime/
chown -R nobody: www/assets/
chown -R nobody: www/runtime/
chmod -R g+rw app/data/
chmod -R g+rw app/runtime/
chmod -R g+rw www/assets/
chmod -R g+rw www/runtime/

# temporarily until it is found enough to only set the user to nobody
chmod -R 777 app/data/
chmod -R 777 app/runtime/
chmod -R 777 www/assets/
chmod -R 777 www/runtime/

# fail on any error
set -o errexit

# install bower dependencies (bower_components are committed when dokku is deployed nowadays)
#node_modules/.bin/bower install --allow-root

# generate the js app
# npm install -g grunt
#cp app/js/config.dist.js app/js/config.js
#grunt build

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