#!/bin/bash
set -e
docker login
docker buildx build --push --platform linux/amd64,linux/arm64 -t intermesh/groupoffice:latest -t intermesh/groupoffice:6.7 .

#docker push intermesh/groupoffice:latest
#docker push intermesh/groupoffice:6.7
