#!/bin/bash
set -e
set -o pipefail
source ./localtesting_vars.sh

echo "Get tenant details"

TENANT=$(./omgserversctl.sh environment printVariable TENANT)
PROJECT=$(./omgserversctl.sh environment printVariable PROJECT)
STAGE=$(./omgserversctl.sh environment printVariable STAGE)
DEVELOPER_USER=$(./omgserversctl.sh environment printVariable DEVELOPER_USER)
DEVELOPER_PASSWORD=$(./omgserversctl.sh environment printVariable DEVELOPER_PASSWORD)

if [ -z "${TENANT}" -o -z "${PROJECT}" -o -z "${STAGE}" -o -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
  echo "Tenant was not initialized, run ./localtesting_init.sh first"
  exit 1
fi

echo TENANT=${TENANT}, ALIAS=${TENANT_ALIAS}
echo PROJECT=${PROJECT}, ALIAS=${PROJECT_ALIAS}
echo STAGE=${STAGE}
echo DEVELOPER_USER=${DEVELOPER_USER}, DEVELOPER_PASSWORD=${DEVELOPER_PASSWORD}