#!/usr/bin/env bash

# fail on any error
set -o errexit

# Uncomment to see all variables used in this sciprt
set -x;

script_path=$(dirname $0)
dna_path=$script_path/../../../../dna

# make app config available as shell variables
source vendor/neam/php-app-config/shell-export.sh

# set media path
media_path=/files/$DATA/media

# configure s3cmd
echo "[default]
access_key = $PUBLIC_FILE_UPLOADERS_ACCESS_KEY
secret_key = $PUBLIC_FILE_UPLOADERS_SECRET" > /tmp/.public-files.s3cfg

if [ "$PUBLIC_FILES_S3_PATH" == "" ]; then
  echo "Empty PUBLIC_FILES_S3_PATH is dangerous"
  exit 1
fi

if [ "$DATA" == "" ]; then
  echo "DATA needs to be set"
  exit 1
fi

# upload current media to public files
s3cmd -v --acl-public --config=/tmp/.public-files.s3cfg --recursive sync $media_path/ "${PUBLIC_FILES_S3_BUCKET}${PUBLIC_FILES_S3_PATH}media/"

exit 0
