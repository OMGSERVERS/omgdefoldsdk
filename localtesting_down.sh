#!/bin/bash
set -e
set -o pipefail
source ./localtesting_vars.sh
docker compose -p omgservers down -v