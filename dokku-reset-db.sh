#!/bin/bash

# this wrapper runs the preparation scripts necessary to reset the database to user-generated data
script_path=`dirname $0`

# fail on any error
set -o errexit

# make sure that the persistent p3media folder exists
bash $script_path/configure-persistent-p3media.sh

# set s3 credentials
bash $script_path/configure-s3cmd.sh

# reset db
connectionID=db bash $script_path/../yii-dna-pre-release-testing/shell-scripts/reset-db.sh