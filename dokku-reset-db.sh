#!/bin/bash

# this wrapper runs the preparation scripts necessary to reset the database to user-generated data
script_path=`dirname $0`

# fail on any error
set -o errexit

# workaround unknown bug that removes executable permission from all files
chmod +x $script_path/*.sh

# make sure that the persistent p3media folder exists
$script_path/configure-persistent-p3media.sh

# set s3 credentials
$script_path/configure-s3cmd.sh

# reset db
connectionID=db $script_path/../shell-scripts/reset-db.sh