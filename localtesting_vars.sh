#!/bin/bash
set -e
set -o pipefail

EXTERNAL_URL="http://localhost:8080"
INTERNAL_URL="http://service:8080"
TENANT_ALIAS="omgservers"
PROJECT_ALIAS="omgdefold"
DOCKER_IMAGE="omgservers/omgdefold:latest"
