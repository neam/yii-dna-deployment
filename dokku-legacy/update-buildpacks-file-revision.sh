#!/bin/bash

# debug
#set -x

# fail on any error
set -o errexit

script_path=`dirname $0`

export BUILDPACK_PHP_REVISION="$(cd $script_path/appsdeck-buildpack-php;git rev-parse --verify HEAD)"

sed -i '' 's/buildpack-php#[^ ]*/buildpack-php#'$BUILDPACK_PHP_REVISION'/g' '.buildpacks'

git  --no-pager diff .buildpacks

exit 0