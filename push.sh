#!/bin/bash
set -e
docker build . -t intermesh/groupoffice:6.6
docker login
docker push intermesh/groupoffice:6.6
