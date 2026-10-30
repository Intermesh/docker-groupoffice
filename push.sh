#!/bin/bash
set -e

# I prepared ubuntu for multi platform build with these commands ( see also https://docs.docker.com/build/building/multi-platform/):

# docker run --privileged --rm tonistiigi/binfmt --install all
# docker buildx rm builder
# docker buildx create --name builder --driver docker-container --use
# docker buildx inspect --bootstrap

# Compiling the PHP extensions for arm64 under QEMU emulation is very slow. Set ARM64_HOST to a docker host
# running on arm64 to build that platform natively and in parallel with amd64, e.g.:
# ARM64_HOST=ssh://user@arm-host ./push.sh
BUILDER_ARGS=""
if [ -n "$ARM64_HOST" ]; then
    if ! docker buildx inspect native > /dev/null 2>&1; then
        docker buildx create --name native --driver docker-container --platform linux/amd64
        docker buildx create --name native --append --platform linux/arm64 "$ARM64_HOST"
    fi
    BUILDER_ARGS="--builder native"
fi

CONTENT=`cat Dockerfile`
REGEX='VERSION=([0-9]+)\.([0-9]+)\.([0-9]+)';

[[ $CONTENT =~ $REGEX ]]

major=${BASH_REMATCH[1]};
minor=${BASH_REMATCH[2]};
patch=${BASH_REMATCH[3]};

docker login
docker buildx build $BUILDER_ARGS \
    --push --pull --platform linux/amd64,linux/arm64 \
    -t intermesh/groupoffice:testing \
    -t intermesh/groupoffice:$major.$minor \
    -t intermesh/groupoffice:$major.$minor.$patch \
    .

