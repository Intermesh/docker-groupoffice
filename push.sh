#!/bin/bash
set -e
docker build --no-cache . -t intermesh/groupoffice:latest
docker login
docker push intermesh/groupoffice:latest
