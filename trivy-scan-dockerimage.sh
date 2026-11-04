#!/bin/bash

set -e

dockerImageName="$1"

if [ -z "$dockerImageName" ]; then
    echo "ERROR: Docker image name is required"
    exit 2
fi

echo "Scanning Docker image: $dockerImageName"

echo "===== HIGH VULNERABILITY SCAN ====="

docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v trivy-cache:/root/.cache/ \
    aquasec/trivy:latest \
    image --exit-code 0 --severity HIGH "$dockerImageName"

echo "===== CRITICAL VULNERABILITY SCAN ====="

docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v trivy-cache:/root/.cache/ \
    aquasec/trivy:latest \
    image --exit-code 1 --severity CRITICAL "$dockerImageName"

    