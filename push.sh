#!/bin/bash
set -e


CONTENT=`cat Dockerfile`
REGEX='VERSION=([0-9]+)\.([0-9]+)\.([0-9]+)';

[[ $CONTENT =~ $REGEX ]]

major=${BASH_REMATCH[1]};
minor=${BASH_REMATCH[2]};
patch=${BASH_REMATCH[3]};

docker pull php:8.2-apache

docker login
docker buildx build \
    --push --platform linux/amd64,linux/arm64 \
    -t intermesh/groupoffice:latest \
    -t intermesh/groupoffice:$major.$minor \
    -t intermesh/groupoffice:$major.$minor.$patch \
    .
