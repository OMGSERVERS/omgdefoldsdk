#!/bin/bash
set -e
set -o pipefail
source ./localtesting_vars.sh

docker compose -p omgservers -f docker/compose.yaml up --remove-orphans -d
docker compose -p omgservers ps