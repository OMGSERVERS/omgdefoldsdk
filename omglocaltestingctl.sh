#!/bin/bash
set -e
set -o pipefail
source omglocaltestingctl.env
export TZ=UTC

# INTERNAL

internal_print_command() {
  printf "  %-60s %s\n" "$1" "$2"
}

# HANDLERS

handler_help() {
  echo "OMGLOCALTESTING ctl, v${OMGSERVERS_VERSION}"
  echo "Usage:"
  if [ -z "$1" -o "$1" = "help" ]; then
    internal_print_command " $0 help" "Display this help message."
  fi
  if [ -z "$1" -o "$1" = "up" ]; then
    internal_print_command " $0 up" "Start the local environment."
  fi
  if [ -z "$1" -o "$1" = "ps" ]; then
    internal_print_command " $0 ps" "List running containers."
  fi
  if [ -z "$1" -o "$1" = "logs" ]; then
    internal_print_command " $0 logs [options]" "Show container logs."
  fi
  if [ -z "$1" -o "$1" = "down" ]; then
    internal_print_command " $0 down" "Stop the local environment."
  fi
  if [ -z "$1" -o "$1" = "reset" ]; then
    internal_print_command " $0 reset" "Reset the local environment."
  fi
  if [ -z "$1" -o "$1" = "init" ]; then
    internal_print_command " $0 init" "Initialize a tenant and developer account."
  fi
  if [ -z "$1" -o "$1" = "build" ]; then
    internal_print_command " $0 build" "Build a Docker image."
  fi
  if [ -z "$1" -o "$1" = "install" ]; then
    internal_print_command " $0 install" "Install a Docker image locally."
  fi
  if [ -z "$1" -o "$1" = "deploy" ]; then
    internal_print_command " $0 deploy <url> <user> <password>" "Deploy a Docker image to the server."
  fi
}

handler_ps() {
  docker compose -p omgservers ps --format "table {{.Name}}\t{{.Image}}\t{{.State}}\t{{.Ports}}"
}

handler_up() {
  OMGSERVERS_VERSION=${OMGSERVERS_VERSION} docker compose -p omgservers -f localtesting/compose.yaml up --remove-orphans -d
  handler_ps
}

handler_logs() {
  docker compose -p omgservers logs $@
}

handler_down() {
  docker compose -p omgservers down -v
}

handler_init() {
  echo "$(date) Using, TENANT_ALIAS=\"${TENANT_ALIAS}\""
  echo "$(date) Using, PROJECT_ALIAS=\"${PROJECT_ALIAS}\""
  echo "$(date) Using, STAGE_ALIAS=\"${STAGE_ALIAS}\""

  ./omgserversctl.sh environment useEnvironment local "http://localhost:8080"

  echo "$(date) Create a new tenant"

  ./omgserversctl.sh support createToken "support" "support"
  ./omgserversctl.sh support createTenant

  TENANT=$(./omgserversctl.sh environment printVariable TENANT)
  if [ -z "${TENANT}" ]; then
    echo "ERROR: TENANT was not found" >&2
    exit 1
  fi

  ./omgserversctl.sh support createTenantAlias ${TENANT} ${TENANT_ALIAS}

  echo "$(date) Create a new project"

  ./omgserversctl.sh support createProject ${TENANT_ALIAS}

  PROJECT=$(./omgserversctl.sh environment printVariable PROJECT)
  if [ -z "${PROJECT}" ]; then
    echo "ERROR: PROJECT was not found" >&2
    exit 1
  fi

  STAGE=$(./omgserversctl.sh environment printVariable STAGE)
  if [ -z "${STAGE}" ]; then
    echo "ERROR: STAGE was not found" >&2
    exit 1
  fi

  ./omgserversctl.sh support createProjectAlias ${TENANT_ALIAS} ${PROJECT} ${PROJECT_ALIAS}
  ./omgserversctl.sh support createStageAlias ${TENANT_ALIAS} ${STAGE} ${STAGE_ALIAS}

  echo "$(date) Create a new developer account"

  ./omgserversctl.sh support createDeveloper

  DEVELOPER_USER=$(./omgserversctl.sh environment printVariable DEVELOPER_USER)
  if [ -z "${DEVELOPER_USER}" ]; then
    echo "ERROR: DEVELOPER_USER was not found" >&2
    exit 1
  fi

  DEVELOPER_PASSWORD=$(./omgserversctl.sh environment printVariable DEVELOPER_PASSWORD)
  if [ -z "${DEVELOPER_PASSWORD}" ]; then
    echo "ERROR: DEVELOPER_PASSWORD was not found" >&2
    exit 1
  fi

  echo "$(date) Configure developer permissions"

  ./omgserversctl.sh support createTenantPermission ${TENANT_ALIAS} ${DEVELOPER_USER} TENANT_VIEWER
  ./omgserversctl.sh support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} VERSION_MANAGER
  ./omgserversctl.sh support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} PROJECT_VIEWER
  ./omgserversctl.sh support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} DEPLOYMENT_MANAGER
  ./omgserversctl.sh support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} STAGE_VIEWER

  echo "$(date) Login using developer account, DEVELOPER_USER=\"${DEVELOPER_USER}\", DEVELOPER_PASSWORD=\"${DEVELOPER_PASSWORD}\""

  ./omgserversctl.sh developer createToken ${DEVELOPER_USER} ${DEVELOPER_PASSWORD}

  echo "$(date) All is done"
}

handler_deploy() {
  SERVICE_URL=$1
  DEVELOPER_USER=$2
  DEVELOPER_PASSWORD=$3

  if [ -z "${SERVICE_URL}" -o -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    handler_help "deploy"
    exit 1
  fi

  echo "$(date) Using, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""
  echo "$(date) Using, SERVICE_URL=\"${SERVICE_URL}\""
  echo "$(date) Using, DEVELOPER_USER=\"${DEVELOPER_USER}\""
  echo "$(date) Using, TENANT_ALIAS=\"${TENANT_ALIAS}\""
  echo "$(date) Using, PROJECT_ALIAS=\"${PROJECT_ALIAS}\""
  echo "$(date) Using, STAGE_ALIAS=\"${STAGE_ALIAS}\""

  echo "$(date) Login using developer account"

  ./omgserversctl.sh environment useEnvironment target "${SERVICE_URL}"
  ./omgserversctl.sh developer createToken "${DEVELOPER_USER}" "${DEVELOPER_PASSWORD}"

  echo "$(date) Create a new version"

  ./omgserversctl.sh developer createVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} "./config.json"
  VERSION=$(./omgserversctl.sh environment printVariable VERSION)
  if [ -z "${VERSION}" -o "${VERSION}" == "null" ]; then
    echo "ERROR: VERSION was not found" >&2
    exit 1
  fi

  echo "$(date) Push docker image"

  REGISTRY_SERVER=$(echo ${SERVICE_URL} | sed 's/^https*:\/\///')
  echo "$(date) Using, REGISTRY_SERVER=${REGISTRY_SERVER}"

  TARGET_IMAGE="${REGISTRY_SERVER}/omgservers/${TENANT_ALIAS}/${PROJECT_ALIAS}/universal:${VERSION}"
  docker login -u ${DEVELOPER_USER} -p ${DEVELOPER_PASSWORD} "${REGISTRY_SERVER}"
  docker tag ${DOCKER_IMAGE} ${TARGET_IMAGE}
  docker push ${TARGET_IMAGE}

  echo "$(date) Deploy a new version"

  ./omgserversctl.sh developer deployVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE_ALIAS} ${VERSION}
  DEPLOYMENT=$(./omgserversctl.sh environment printVariable DEPLOYMENT)
  if [ -z "${DEPLOYMENT}" -o "${DEPLOYMENT}" == "null" ]; then
    echo "ERROR: DEPLOYMENT was not found" >&2
    exit 1
  fi

  echo "$(date) All is done"
}

handler_install() {
  DEVELOPER_USER=$(./omgserversctl.sh environment printVariable DEVELOPER_USER)
  DEVELOPER_PASSWORD=$(./omgserversctl.sh environment printVariable DEVELOPER_PASSWORD)

  if [ -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    echo "ERROR: Localtesting developer account was not found" >&2
    exit 1
  fi

  handler_deploy "http://localhost:8080" "${DEVELOPER_USER}" "${DEVELOPER_PASSWORD}"
}

handler_reset() {
  handler_down
  handler_up
}

handler_build() {
  echo "$(date) Using, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""

  docker build --build-arg OMGSERVERS_VERSION="${OMGSERVERS_VERSION}" -t "${DOCKER_IMAGE}" .
  echo "$(date) The image \"${DOCKER_IMAGE}\" has been built."
}

if [ "$1" = "help" ]; then
  shift
  handler_help "$*"
elif [ "$1" = "up" ]; then
  handler_up
elif [ "$1" = "ps" ]; then
  handler_ps
elif [ "$1" = "logs" ]; then
  shift
  handler_logs $@
elif [ "$1" = "down" ]; then
  handler_down
elif [ "$1" = "reset" ]; then
  handler_reset
elif [ "$1" = "init" ]; then
  handler_init
elif [ "$1" = "build" ]; then
  handler_build
elif [ "$1" = "install" ]; then
  handler_install
elif [ "$1" = "deploy" ]; then
  shift
  handler_deploy $@
else
  handler_help
fi
