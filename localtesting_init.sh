#!/bin/bash
set -e
set -o pipefail
source ./localtesting_vars.sh

./omgserversctl.sh environment useEnvironment docker "${INTERNAL_URL}"

echo "Create a new tenant"

./omgserversctl.sh support useCredentials "support" "support"
./omgserversctl.sh support createToken
./omgserversctl.sh support createTenant

TENANT=$(./omgserversctl.sh environment printVariable TENANT)
if [ -z "${TENANT}" ]; then
  echo "TENANT was not found"
  exit 1
fi

./omgserversctl.sh support createTenantAlias ${TENANT} ${TENANT_ALIAS}

echo "Create a new project"

./omgserversctl.sh support createProject ${TENANT_ALIAS}

PROJECT=$(./omgserversctl.sh environment printVariable PROJECT)
if [ -z "${PROJECT}" ]; then
  echo "PROJECT was not found"
  exit 1
fi

STAGE=$(./omgserversctl.sh environment printVariable STAGE)
if [ -z "${STAGE}" ]; then
  echo "STAGE was not found"
  exit 1
fi

./omgserversctl.sh support createProjectAlias ${TENANT_ALIAS} ${PROJECT} ${PROJECT_ALIAS}

echo "Create a new developer account"

./omgserversctl.sh support createDeveloper

DEVELOPER_USER=$(./omgserversctl.sh environment printVariable DEVELOPER_USER)
if [ -z "${DEVELOPER_USER}" ]; then
  echo "DEVELOPER_USER was not found"
  exit 1
fi

DEVELOPER_PASSWORD=$(./omgserversctl.sh environment printVariable DEVELOPER_PASSWORD)
if [ -z "${DEVELOPER_PASSWORD}" ]; then
  echo "DEVELOPER_PASSWORD was not found"
  exit 1
fi

echo "Configure developer permissions"

./omgserversctl.sh support createTenantPermission ${TENANT_ALIAS} ${DEVELOPER_USER} TENANT_VIEWER
./omgserversctl.sh support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} VERSION_MANAGER
./omgserversctl.sh support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} PROJECT_VIEWER
./omgserversctl.sh support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} DEPLOYMENT_MANAGER
./omgserversctl.sh support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} STAGE_VIEWER

echo "Login using developer account"

./omgserversctl.sh developer useCredentials ${DEVELOPER_USER} ${DEVELOPER_PASSWORD}

echo "Output details"

echo TENANT=${TENANT}, ALIAS=${TENANT_ALIAS}
echo PROJECT=${PROJECT}, ALIAS=${PROJECT_ALIAS}
echo STAGE=${STAGE}
echo DEVELOPER_USER=${DEVELOPER_USER}, DEVELOPER_PASSWORD=${DEVELOPER_PASSWORD}

CONFIG="./client/localtesting.lua"
cat > ${CONFIG} << EOF
return {
  url = "${EXTERNAL_URL}",
  tenant = "${TENANT_ALIAS}",
  project = "${PROJECT_ALIAS}",
  stage = "${STAGE}",
}
EOF
echo "Project file ${CONFIG} was written"
cat ${CONFIG}

echo "All is done"