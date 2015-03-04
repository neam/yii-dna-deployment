#!/usr/bin/env bash

# Regenerates site.conf based on the current composer.json and reloads nginx to make the changes active

# Uncomment to enable debug

#set -x

# Regenerate

export PORT=5000

source /exec

cd $PROJECT_ROOT

export DOCUMENT_ROOT="$(jq --raw-output '.extra.heroku["document-root"] // ""' < composer.json)"
export INDEX_DOCUMENT="$(jq --raw-output '.extra.heroku["index-document"] // ""' < composer.json)"
export NGINX_INCLUDES="$(jq --raw-output '.extra.heroku["nginx-includes"] // ""' < composer.json)"
export NGINX_LOCATIONS="$(jq --raw-output '.extra.heroku["nginx-locations"] // []' < composer.json)"

#erb /app/conf/nginx.conf.erb > /app/vendor/nginx/conf/nginx.conf
erb /app/conf/site.conf.erb > /app/vendor/nginx/conf/site.conf

echo "Nginx configuration regenerated based on $PROJECT_ROOT/composer.json"
echo
echo "To inspect the new configuration:"
echo
echo "   less /app/vendor/nginx/conf/site.conf"
echo

nginx -s reload && echo "Nginx configuration reloaded"
