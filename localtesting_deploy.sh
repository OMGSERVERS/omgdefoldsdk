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
  echo "Tenant was not initialized, use ./localtesting_init.sh first"
  exit 1
fi

echo TENANT=${TENANT}, ALIAS=${TENANT_ALIAS}
echo PROJECT=${PROJECT}, ALIAS=${PROJECT_ALIAS}
echo STAGE=${STAGE}
echo DEVELOPER_USER=${DEVELOPER_USER}, DEVELOPER_PASSWORD=${DEVELOPER_PASSWORD}

echo "Login using developer account"

./omgserversctl.sh developer createToken

echo "Create a new version"

./omgserversctl.sh developer createVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} "./config.json"
VERSION=$(./omgserversctl.sh environment printVariable VERSION)
if [ -z "${VERSION}" -o "${VERSION}" == "null" ]; then
  echo "ERROR: VERSION was not received"
  exit 1
fi

echo "Push docker image"

TARGET_IMAGE="localhost:5000/omgservers/${TENANT}/${PROJECT}/universal:${VERSION}"
docker login -u ${DEVELOPER_USER} -p ${DEVELOPER_PASSWORD} localhost:5000
docker tag ${DOCKER_IMAGE} ${TARGET_IMAGE}
docker push ${TARGET_IMAGE}

echo "Deploy a new version"

./omgserversctl.sh developer deployVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${VERSION}
DEPLOYMENT=$(./omgserversctl.sh environment printVariable DEPLOYMENT)
if [ -z "${DEPLOYMENT}" -o "${DEPLOYMENT}" == "null" ]; then
  echo "ERROR: DEPLOYMENT was not received"
  exit 1
fi

echo "All is done"