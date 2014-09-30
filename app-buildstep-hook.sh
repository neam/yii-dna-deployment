#!/bin/bash

# This file performs certain actions in the end of the buildpack build process,
# thus changes here are compiled into the application slug.
# The working directory is $BUILD_DIR

# debug
set -x

# fail on any error
set -o errexit

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

# === selected logic from chh/heroku-buildpack-php bin/compile_node

    if [ -f "package.json" ]; then

        # Configure directories
        build_dir="$BUILD_DIR"
        cache_basedir="$CACHE_DIR"
        bp_dir="$basedir"

        # Output npm debug info on error
        trap cat_npm_debug_log ERR

        if test -f $build_dir/npm-shrinkwrap.json; then
          # Use npm-shrinkwrap.json's checksum as the cachebuster
          status "Found npm-shrinkwrap.json"
          shrinkwrap_checksum=$(cat $build_dir/npm-shrinkwrap.json | md5sum | awk '{print $1}')
          cache_dir="$cache_basedir/$shrinkwrap_checksum"
          test -d $cache_dir && status "npm-shrinkwrap.json unchanged since last build"
        else
          # Fall back to package.json as the cachebuster.
          protip "Use npm shrinkwrap to lock down dependency versions"
          package_json_checksum=$(cat $build_dir/package.json | md5sum | awk '{print $1}')
          cache_dir="$cache_basedir/$package_json_checksum"
          test -d $cache_dir && status "package.json unchanged since last build"
        fi

        if test -d $cache_dir; then
          status "Restoring node_modules from cache"
          test -d $cache_dir/node_modules && cp -r $cache_dir/node_modules $build_dir/
        fi

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
            php "$BUILD_DIR/vendor/composer/bin/composer.phar" install \
                --prefer-dist \
                --optimize-autoloader \
                --no-interaction \
                --no-dev
            cd "$cwd"
        } | indent

    fi

# === yii-dna custom logic

    # install bower dependencies (requires bower to be installed in root project dir)

    if [ -f "bower.json" ] && [ -f "$BUILD_DIR/node_modules/.bin/bower" ]; then

        $BUILD_DIR/node_modules/.bin/bower install --allow-root

    fi

    # set writable paths

    paths=$(jq --raw-output '.extra.writable // [] | .[]' < "composer.json")
    if [ "$paths" != "" ]; then
        while read -r p; do
            chown -R nobody: "$p"
            chmod -R g+rw "$p"
            chmod -R 777 "$p" # currently seems necessary
        done <<< "$paths"
    fi

exit 0