#!/bin/bash

# This file performs certain actions in the end of the buildpack build process,
# thus changes here are compiled into the application slug.
# The working directory is $BUILD_DIR

# debug
set -x

# buildpack paths are sent as the first three arguments
BUILD_DIR="$1"
CACHE_DIR="$2"
basedir="$3"

# fourth argument: relative path to folder to perform actions within
REL_PATH="$4"

# Load some convenience functions like status() echo(), indent()
source $basedir/common.sh

# step into the folder to perform actions within
cd $BUILD_DIR/$REL_PATH

# === selected logic from heroku-buildpack-php/bin/compile_node

    if [ -f "package.json" ]; then

        # Configure directories
        build_dir="$BUILD_DIR"
        cache_basedir="$CACHE_DIR"
        bp_dir="$basedir"

        # Output npm debug info on error
        trap cat_npm_debug_log ERR

        status "Installing dependencies"
        npm install --production 2>&1 | indent

        status "Pruning unused dependencies"
        npm prune 2>&1 | indent

        status "Caching node_modules for future builds"
        rm -rf $cache_dir
        mkdir -p $cache_dir
        test -d $build_dir/node_modules && cp -r $build_dir/node_modules $cache_dir/

        status "Cleaning up node-gyp and npm artifacts"
        rm -rf "$build_dir/.node-gyp"
        rm -rf "$build_dir/.npm"

    fi

# === selected logic from heroku-buildpack-php/bin/compile

    if [ -f "composer.lock" ]; then

        status "Installing application dependencies with Composer"
        {
            cd "$target"
            php "vendor/composer/bin/composer.phar" install \
                --prefer-dist \
                --optimize-autoloader \
                --no-interaction \
                --no-dev
            cd "$cwd"
        } | indent

    fi

# === yii-dna custom logic

    # install bower dependencies

    if [ -f "bower.json" ]; then

        npm install -g bower
        node_modules/.bin/bower install --allow-root

    fi

    # set writable paths

    paths=$(jq --raw-output '.extra.writable // [] | .[]' < "composer.json")
    for fn in "$paths"; do
        chown -R nobody: app/data/
        chmod -R g+rw app/data/
        chmod -R 777 app/data/ # currently necessary since above is not enough for heroku-buildpack-php
    done

exit 0