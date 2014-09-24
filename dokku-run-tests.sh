#!/bin/bash

# runs tests against the current deployment
# expects that reset-db.sh has been executed just before and that CONFIG_ENVIRONMENT has been set to "ci"

# The following env vars needs to be set properly:
# - SAUCE_USERNAME
# - SAUCE_ACCESS_KEY
# - COMPOSER_GITHUB_OAUTH_TOKEN
# - CMS_BASE_URL
# - CONFIG_ENVIRONMENT
# - COVERAGE

# debug
set -x

# fail on any error
set -o errexit

# get arguments
COVERAGE=$1

# initialize env vars so that we have app config and PATH properly set
export HOME=/app
for file in /app/.profile.d/*; do source $file; done
cd $HOME
cd tests

# make sure $COMPOSER_GITHUB_TOKEN is used by composer
if [ -n "$COMPOSER_GITHUB_TOKEN" ]; then
    status "Configuring the github authentication for Composer"
    php ../composer.phar config -g github-oauth.github.com "$COMPOSER_GITHUB_TOKEN" --no-interaction
fi

# info
echo "Running tests with coverage '$COVERAGE' in config environment '$CONFIG_ENVIRONMENT'"

# install test deps
export COMPOSER_NO_INTERACTION=1
php ../composer.phar install --dev --prefer-dist

# set the codeception test group arguments depending on DATA and COVERAGE
source _set-codeception-group-args.sh

# run unit tests (against a test database)

    # make sure the db_test database exists and is empty
    export DB_NAME_ORG=$DB_NAME
    export DB_NAME=db_test
    echo "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;" | mysql -h$DB_HOST -P$DB_PORT -u$DB_USER --password=$DB_PASSWORD

    # generate local test config
    export SAUCELABS=0
    ./generate-local-codeception-config.sh
    vendor/bin/codecept build

    # reset the test database to a clean db state
    export CONFIG_ENVIRONMENT=test
    export DATA=clean-db
    connectionID=dbTest ../shell-scripts/reset-db.sh

    # run the actual unit tests
    ../app/yiic mysqldump --connectionID=dbTest --dumpPath=tests/codeception/_data/
    vendor/bin/codecept run unit $CODECEPTION_GROUP_ARGS --fail-fast

    # restore DB_NAME
    export DB_NAME=$DB_NAME_ORG

# prepare acceptance tests

    # set saucelabs-specific env vars (note: saucelabs ui only allows useful filtering for short tags - 10 chars and less)
    export SAUCE_METADATA_BUILD=$CI_BUILD_ID
    export SAUCE_METADATA_DEFAULT_TAGS=cms,data:$DATA,coverage:$COVERAGE,deployment:$ENV,base_url:$CMS_BASE_URL
    export CMS_HOST=$CMS_BASE_URL # todo - use CMS_BASE_URL in codeception config instead

    # take an initial db dump before any tests have been run (it is used below to restore the database before the desktop-sized tests are run)
    mysqldump --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" --port="$DB_PORT" --no-create-db "$DB_NAME" > /tmp/pre-acceptance-tests-dump.sql

# run acceptance tests on a small-screen chrome, "mobile"

    # generate local test config
    export SAUCELABS=1
    export SAUCE_METADATA_TAGS=small-screen,$SAUCE_METADATA_DEFAULT_TAGS
    ./generate-local-codeception-config.sh
    vendor/bin/codecept build

    export env=cms-saucelabs-chrome-win7-small-oblong
    vendor/bin/codecept run acceptance-init --env=$env $CODECEPTION_GROUP_ARGS --debug --fail-fast
    #mysqldump --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" --port="$DB_PORT" --no-create-db db > codeception/_data/dump.sql
    vendor/bin/codecept run acceptance --env=$env $CODECEPTION_GROUP_ARGS --debug --fail-fast

# reset the database prior to running acceptance tests anew

    mysql -A --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" "$DB_NAME" < /tmp/pre-acceptance-tests-dump.sql

# run acceptance tests on a desktop-sized screen

    # generate local test config
    export SAUCELABS=1
    export SAUCE_METADATA_TAGS=desktop,$SAUCE_METADATA_DEFAULT_TAGS
    ./generate-local-codeception-config.sh
    vendor/bin/codecept build

    export env=cms-saucelabs-chrome-win8
    #export env=cms-saucelabs-firefox-win7
    #export env=cms-saucelabs-chrome-osx-108
    vendor/bin/codecept run acceptance-init --env=$env $CODECEPTION_GROUP_ARGS --debug --fail-fast
    #mysqldump --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" --port="$DB_PORT" --no-create-db db > codeception/_data/dump.sql
    vendor/bin/codecept run acceptance --env=$env $CODECEPTION_GROUP_ARGS --debug --fail-fast

# run api tests

    vendor/bin/codecept run api $CODECEPTION_GROUP_ARGS --debug --fail-fast

exit 0
