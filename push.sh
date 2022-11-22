#!/bin/bash
set -e
docker build --no-cache . -t intermesh/groupoffice:testing
docker login
docker push intermesh/groupoffice:testing
