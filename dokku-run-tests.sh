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
CI_TESTS_ENTRY_SCRIPT=$2

# initialize env vars so that we have app config and PATH properly set
export HOME=/app
for file in /app/.profile.d/*; do source $file; done
cd $HOME
cd vendor/neam/yii-dna-test-framework

# make sure $COMPOSER_GITHUB_TOKEN is used by composer
if [ -n "$COMPOSER_GITHUB_TOKEN" ]; then
    status "Configuring the github authentication for Composer"
    php $HOME/composer.phar config -g github-oauth.github.com "$COMPOSER_GITHUB_TOKEN" --no-interaction
fi

# info
echo "About to run tests with coverage '$COVERAGE' in config environment '$CONFIG_ENVIRONMENT'"

# install test deps
export COMPOSER_NO_INTERACTION=1
php $HOME/composer.phar install --dev --prefer-dist

# set the codeception test group arguments depending on DATA and COVERAGE
source _set-codeception-group-args.sh

# run ci tests entry script
$CI_TESTS_ENTRY_SCRIPT

exit 0
