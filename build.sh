#!/usr/bin/env bash

# Stop running the script on an error
set -e

# Set the project name
NAME=tenant-data-manager
# Parse the variables
TAG=${1:-`git rev-parse --short HEAD`}

# Build the runtime containers
docker build -f Dockerfile -t kineticdata/$NAME:$TAG .

# Echo command for running
echo ""
echo "Push Command: docker push kineticdata/$NAME:$TAG"
echo "Run Command:  docker run -p 4567:4567 --name $NAME --rm kineticdata/$NAME:$TAG"
echo ""
