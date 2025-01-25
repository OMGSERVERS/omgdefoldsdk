#!/bin/bash
set -e
set -o pipefail

SERVICE_URL="http://localhost:8080"
TENANT_ALIAS="omgservers"
PROJECT_ALIAS="omgdefold"
DOCKER_IMAGE="omgservers/omgdefold:latest"

# HANDLERS

handler_help() {
  echo "LOCALTESTING ctl, v1.0.0"
  echo "Usage:"
  if [ -z "$1" -o "$1" = "help" ]; then
    echo " ./localtesting.sh help - display this help message"
  fi
  if [ -z "$1" -o "$1" = "boot" ]; then
    echo " ./localtesting.sh boot - bootstrap the project server-side"
  fi
  if [ -z "$1" -o "$1" = "up" ]; then
    echo " ./localtesting.sh up - start the environment"
  fi
  if [ -z "$1" -o "$1" = "ps" ]; then
    echo " ./localtesting.sh ps - list environment containers"

  fi
  if [ -z "$1" -o "$1" = "ctl" ]; then
    echo " ./localtesting.sh ctl <options> - execute OMGSERVERS CTL command"
  fi
  if [ -z "$1" -o "$1" = "logs" ]; then
    echo " ./localtesting.sh logs <options> - display environment logs"
  fi
  if [ -z "$1" -o "$1" = "down" ]; then
    echo " ./localtesting.sh down - stop the environment"
  fi
  if [ -z "$1" -o "$1" = "reset" ]; then
    echo " ./localtesting.sh reset - reset the environment"
  fi
  if [ -z "$1" -o "$1" = "init" ]; then
    echo " ./localtesting.sh init - initialize local tenant and developer account"
  fi
  if [ -z "$1" -o "$1" = "details" ]; then
    echo " ./localtesting.sh details - show server-side project details"
  fi
  if [ -z "$1" -o "$1" = "build" ]; then
    echo " ./localtesting.sh build - build the game runtime Docker container"
  fi
  if [ -z "$1" -o "$1" = "deploy" ]; then
    echo " ./localtesting.sh deploy - deploy the game runtime"
  fi
}

handler_boot() {
  handler_init
  handler_build
  handler_deploy
}

handler_up() {
  docker compose -p omgservers -f docker/compose.yaml up --remove-orphans -d
  docker compose -p omgservers ps
}

handler_ps() {
  docker compose -p omgservers ps
}

handler_ctl() {
  docker run --rm -it \
    --network=host \
    -v ${PWD}/.omgserversctl:/opt/omgserversctl/.omgserversctl \
    -v ${PWD}/config.json:/opt/omgserversctl/config.json \
    omgservers/ctl:1.0.0-SNAPSHOT $@
}

handler_logs() {
  docker compose -p omgservers logs $@
}

handler_down() {
  docker compose -p omgservers down -v
}

handler_reset() {
  handler_down
  handler_up
}

handler_init() {
  handler_ctl environment useEnvironment docker "${SERVICE_URL}"

  echo "Create a new tenant"

  handler_ctl support useCredentials "support" "support"
  handler_ctl support createToken
  handler_ctl support createTenant

  TENANT=$(handler_ctl environment printVariable TENANT)
  if [ -z "${TENANT}" ]; then
    echo "TENANT was not found"
    exit 1
  fi

  handler_ctl support createTenantAlias ${TENANT} ${TENANT_ALIAS}

  echo "Create a new project"

  handler_ctl support createProject ${TENANT_ALIAS}

  PROJECT=$(handler_ctl environment printVariable PROJECT)
  if [ -z "${PROJECT}" ]; then
    echo "PROJECT was not found"
    exit 1
  fi

  STAGE=$(handler_ctl environment printVariable STAGE)
  if [ -z "${STAGE}" ]; then
    echo "STAGE was not found"
    exit 1
  fi

  handler_ctl support createProjectAlias ${TENANT_ALIAS} ${PROJECT} ${PROJECT_ALIAS}

  echo "Create a new developer account"

  handler_ctl support createDeveloper

  DEVELOPER_USER=$(handler_ctl environment printVariable DEVELOPER_USER)
  if [ -z "${DEVELOPER_USER}" ]; then
    echo "DEVELOPER_USER was not found"
    exit 1
  fi

  DEVELOPER_PASSWORD=$(handler_ctl environment printVariable DEVELOPER_PASSWORD)
  if [ -z "${DEVELOPER_PASSWORD}" ]; then
    echo "DEVELOPER_PASSWORD was not found"
    exit 1
  fi

  echo "Configure developer permissions"

  handler_ctl support createTenantPermission ${TENANT_ALIAS} ${DEVELOPER_USER} TENANT_VIEWER
  handler_ctl support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} VERSION_MANAGER
  handler_ctl support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} PROJECT_VIEWER
  handler_ctl support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} DEPLOYMENT_MANAGER
  handler_ctl support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} STAGE_VIEWER

  echo "Login using developer account"

  handler_ctl developer useCredentials ${DEVELOPER_USER} ${DEVELOPER_PASSWORD}

  echo "Output details"

  echo TENANT=${TENANT}, ALIAS=${TENANT_ALIAS}
  echo PROJECT=${PROJECT}, ALIAS=${PROJECT_ALIAS}
  echo STAGE=${STAGE}
  echo DEVELOPER_USER=${DEVELOPER_USER}, DEVELOPER_PASSWORD=${DEVELOPER_PASSWORD}

  CONFIG="./client/localtesting.lua"
  cat > ${CONFIG} << EOF
return {
  url = "${SERVICE_URL}",
  tenant = "${TENANT_ALIAS}",
  project = "${PROJECT_ALIAS}",
  stage = "${STAGE}",
}
EOF
  echo "Project file ${CONFIG} was written"
  cat ${CONFIG}

  echo "All is done"
}

handler_details() {
  echo "Get project details"

  TENANT=$(handler_ctl environment printVariable TENANT)
  PROJECT=$(handler_ctl environment printVariable PROJECT)
  STAGE=$(handler_ctl environment printVariable STAGE)
  DEVELOPER_USER=$(handler_ctl environment printVariable DEVELOPER_USER)
  DEVELOPER_PASSWORD=$(handler_ctl environment printVariable DEVELOPER_PASSWORD)

  if [ -z "${TENANT}" -o -z "${PROJECT}" -o -z "${STAGE}" -o -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    echo "Tenant was not initialized, run ./localtesting_init.sh first"
    exit 1
  fi

  echo TENANT=${TENANT}, ALIAS=${TENANT_ALIAS}
  echo PROJECT=${PROJECT}, ALIAS=${PROJECT_ALIAS}
  echo STAGE=${STAGE}
  echo DEVELOPER_USER=${DEVELOPER_USER}, DEVELOPER_PASSWORD=${DEVELOPER_PASSWORD}
}

handler_build() {
  echo "Building \"${DOCKER_IMAGE}\""
  docker build -t ${DOCKER_IMAGE} .
  echo "\"${DOCKER_IMAGE}\" is built"
}

handler_deploy() {
  echo "Get tenant details"

  TENANT=$(handler_ctl environment printVariable TENANT)
  PROJECT=$(handler_ctl environment printVariable PROJECT)
  STAGE=$(handler_ctl environment printVariable STAGE)
  DEVELOPER_USER=$(handler_ctl environment printVariable DEVELOPER_USER)
  DEVELOPER_PASSWORD=$(handler_ctl environment printVariable DEVELOPER_PASSWORD)

  if [ -z "${TENANT}" -o -z "${PROJECT}" -o -z "${STAGE}" -o -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    echo "Tenant was not initialized, use ./localtesting_init.sh first"
    exit 1
  fi

  echo TENANT=${TENANT}, ALIAS=${TENANT_ALIAS}
  echo PROJECT=${PROJECT}, ALIAS=${PROJECT_ALIAS}
  echo STAGE=${STAGE}
  echo DEVELOPER_USER=${DEVELOPER_USER}, DEVELOPER_PASSWORD=${DEVELOPER_PASSWORD}

  echo "Login using developer account"

  handler_ctl developer createToken

  echo "Create a new version"

  handler_ctl developer createVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} "./config.json"
  VERSION=$(handler_ctl environment printVariable VERSION)
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

  handler_ctl developer deployVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${VERSION}
  DEPLOYMENT=$(handler_ctl environment printVariable DEPLOYMENT)
  if [ -z "${DEPLOYMENT}" -o "${DEPLOYMENT}" == "null" ]; then
    echo "ERROR: DEPLOYMENT was not received"
    exit 1
  fi

  echo "All is done"
}

if [ "$1" = "boot" ]; then
  handler_boot
elif [ "$1" = "up" ]; then
  handler_up
elif [ "$1" = "ps" ]; then
  handler_ps
elif [ "$1" = "ctl" ]; then
  shift
  handler_ctl $@
elif [ "$1" = "logs" ]; then
  shift
  handler_logs $@
elif [ "$1" = "down" ]; then
  handler_down
elif [ "$1" = "reset" ]; then
  handler_reset
elif [ "$1" = "init" ]; then
  handler_init
elif [ "$1" = "details" ]; then
  handler_details
elif [ "$1" = "build" ]; then
  handler_build
elif [ "$1" = "deploy" ]; then
  handler_deploy
else
  handler_help
fi