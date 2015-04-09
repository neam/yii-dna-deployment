#!/bin/bash

DATABASE_HOST_INSTANCE_MATCH=$1
NEW_DATABASE_NAME=$2
NEW_DATABASE_USER=$3
NEW_DATABASE_PASSWORD=$4

trove --json list | jq '.' > cdbs.json
export CDB_ID=$(cat cdbs.json | jq -c '.[] | {name: .name, id: .id}' | grep $DATABASE_HOST_INSTANCE_MATCH | jq -r '.id')

trove database-create $CDB_ID $NEW_DATABASE_NAME --character_set utf8 --collate utf8_bin
trove --json database-list $CDB_ID > dbs.json

trove user-create $CDB_ID $NEW_DATABASE_USER $NEW_DATABASE_PASSWORD --databases $NEW_DATABASE_NAME
#trove user-grant-access $DEV_CDB_ID <name> <databases>

