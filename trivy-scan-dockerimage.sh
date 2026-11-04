dockerImageName = $(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

docker run --rm \
  -v ~/trivy-cache:/root/.cache/ \
  aquasec/trivy:latest \
  image --exit-code 0 --severity HIGH --light $dockerImageName

docker run --rm \
  -v ~/trivy-cache:/root/.cache/ \
  aquasec/trivy:latest \
  image --exit-code 1 --severity CRITICAL --light $dockerImageName

exit_code=$?
echo "Trivy scan exit code: $exit_code"

if [ $exit_code -eq 0 ]; then
  echo "No critical vulnerabilities found."
elif [ $exit_code -eq 1 ]; then
  echo "Critical vulnerabilities found. Failing the build."
  exit 1
else
  echo "Trivy scan failed with exit code: $exit_code"
  exit $exit_code
fi