#!/bin/bash
set -e

# I prepared ubuntu for multi platform build with these commands ( see also https://docs.docker.com/build/building/multi-platform/):

# docker run --privileged --rm tonistiigi/binfmt --install all
# docker buildx rm builder
# docker buildx create --name builder --driver docker-container --use
# docker buildx inspect --bootstrap


CONTENT=`cat Dockerfile`
REGEX='VERSION=([0-9]+)\.([0-9]+)\.([0-9]+)';

[[ $CONTENT =~ $REGEX ]]

major=${BASH_REMATCH[1]};
minor=${BASH_REMATCH[2]};
patch=${BASH_REMATCH[3]};

docker pull php:8.3-apache

docker login
docker buildx build \
    --push --no-cache --platform linux/amd64,linux/arm64 \
    -t intermesh/groupoffice:latest \
    -t intermesh/groupoffice:$major.$minor \
    -t intermesh/groupoffice:$major.$minor.$patch \
    .

