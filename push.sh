#!/bin/bash
set -e
docker build --no-cache . -t intermesh/groupoffice:latest -t intermesh/6.7
docker login
docker push intermesh/groupoffice:latest
docker push intermesh/groupoffice:6.7