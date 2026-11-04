
#!/bin/bash

set -e

# Extract Docker image name from Dockerfile
dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)

echo "================================"
echo "Docker Image: $dockerImageName"
echo "================================"

# Scan HIGH vulnerabilities
echo "===== HIGH VULNERABILITY SCAN ====="

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy:latest \
  image --exit-code 0 --severity HIGH "$dockerImageName"

# Scan CRITICAL vulnerabilities
echo "===== CRITICAL VULNERABILITY SCAN ====="

set +e

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy:latest \
  image --exit-code 1 --severity CRITICAL "$dockerImageName"

exit_code=$?

set -e

echo "Trivy scan exit code: $exit_code"

if [ "$exit_code" -eq 0 ]; then
    echo "No critical vulnerabilities found."
elif [ "$exit_code" -eq 1 ]; then
    echo "Critical vulnerabilities found. Failing the build."
    exit 1
else
    echo "Trivy scan failed with exit code: $exit_code"
    exit "$exit_code"
fi
