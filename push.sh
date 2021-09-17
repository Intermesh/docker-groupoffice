#!/bin/bash
set -e
docker build . -t intermesh/groupoffice:latest
docker login
docker push intermesh/groupoffice:latest
