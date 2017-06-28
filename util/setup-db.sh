#!/bin/bash

# fail on any error
set -o errexit

# debug
#set -x

DATABASE_HOST=$1
DATABASE_PORT=$2
NEW_DATABASE_NAME=$3
NEW_DATABASE_USER=$4
NEW_DATABASE_PASSWORD=$5

MYSQLCMD="mysql --no-auto-rehash --host=$DATABASE_HOST --port=$DATABASE_PORT --user=$DATABASE_ROOT_USER --password=$DATABASE_ROOT_PASSWORD"
#MYSQLCMD="$MYSQLCMD --ssl_ca=rds-ssl-ca-cert.pem --ssl-verify-server-cert"

if [ "$DATABASE_ROOT_USER" == "" ]; then
  echo "DATABASE_ROOT_USER needs to be set";
  exit 1
fi
if [ "$DATABASE_ROOT_PASSWORD" == "" ]; then
  echo "DATABASE_ROOT_PASSWORD needs to be set";
  exit 1
fi

MYSQLCMD=cat

echo "CREATE DATABASE IF NOT EXISTS "\`"$NEW_DATABASE_NAME"\`" DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;" | $MYSQLCMD

# http://stackoverflow.com/questions/598190/mysql-check-if-the-user-exists-and-drop-it
echo "GRANT ALL PRIVILEGES ON "\`"$NEW_DATABASE_NAME"\`".* to '$NEW_DATABASE_USER'@'%' IDENTIFIED BY '$NEW_DATABASE_PASSWORD';" | $MYSQLCMD
echo "DROP USER '$NEW_DATABASE_USER'@'%';" | $MYSQLCMD

# create user, making sure that the new user has the currently assigned password
echo "CREATE USER '$NEW_DATABASE_USER'@'%' IDENTIFIED BY '$NEW_DATABASE_PASSWORD';" | $MYSQLCMD
echo "GRANT ALL PRIVILEGES ON "\`"$NEW_DATABASE_NAME"\`".* to '$NEW_DATABASE_USER'@'%' IDENTIFIED BY '$NEW_DATABASE_PASSWORD';" | $MYSQLCMD
echo "FLUSH PRIVILEGES;" | $MYSQLCMD
