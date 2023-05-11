#!/bin/bash
set -e
docker build . -t intermesh/groupoffice:6.6
docker login
docker buildx build --push --platform linux/amd64,linux/arm64 -t intermesh/groupoffice:latest -t intermesh/groupoffice:6.7 .