#!/bin/bash
set -e
docker login
docker buildx build \
    --push --progress=plain --platform linux/amd64 \
    -t intermesh/groupoffice:6.2 \
    .
docker push intermesh/groupoffice:6.2
