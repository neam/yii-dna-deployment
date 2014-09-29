#!/bin/bash

# debug
#set -x

# fail on any error
set -o errexit

script_path=`dirname $0`

export HEROKU_BUILDPACK_PHP_REVISION="$(cd $script_path/heroku-buildpack-php;git rev-parse --verify HEAD)"

sed -i '' 's/heroku-buildpack-php#[^ ]*/heroku-buildpack-php#'$HEROKU_BUILDPACK_PHP_REVISION'/g' '.buildpacks'

git  --no-pager diff .buildpacks

exit 0