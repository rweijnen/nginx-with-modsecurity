#/bin/bash

# Fetch the latest version number from the NGINX website or repository
LATEST_NGINX_VERSION=$(wget -qO- http://nginx.org/en/download.html | grep -oP 'nginx-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)

# Print the latest version number
echo Latest NGINX version: $LATEST_NGINX_VERSION

docker build . -t nginx-with-subsfilter --build-arg NGINX_VERSION=$LATEST_NGINX_VERSION
