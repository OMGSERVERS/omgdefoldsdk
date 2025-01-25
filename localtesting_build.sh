#!/bin/bash
set -e
set -o pipefail
source ./localtesting_vars.sh

echo "Building ${DOCKER_IMAGE}"

docker build -t ${DOCKER_IMAGE} .

echo "${DOCKER_IMAGE} is built"