#!/bin/bash
set -e
set -o pipefail
source omglocaltestingctl.env
export TZ=UTC

# HANDLERS

print_command() {
  printf "  %-40s %s\n" "$1" "$2"
}

handler_help() {
  echo "OMGLOCALTESTING ctl, v${OMGSERVERS_VERSION}"
  echo "Usage:"
  if [ -z "$1" -o "$1" = "help" ]; then
    print_command " $0 help" "Display this help message"
  fi
  if [ -z "$1" -o "$1" = "up" ]; then
    print_command " $0 up" "Start the local environment"
  fi
  if [ -z "$1" -o "$1" = "ps" ]; then
    print_command " $0 ps" "List running containers"
  fi
  if [ -z "$1" -o "$1" = "logs" ]; then
    print_command " $0 logs <options>" "Show container logs"
  fi
  if [ -z "$1" -o "$1" = "down" ]; then
    print_command " $0 down" "Stop the local environment"
  fi
  if [ -z "$1" -o "$1" = "reset" ]; then
    print_command " $0 reset" "Reset the local environment"
  fi
  if [ -z "$1" -o "$1" = "ctl" ]; then
    print_command " $0 ctl" "Execute OMGSERVERS command"
  fi
  if [ -z "$1" -o "$1" = "init" ]; then
    print_command " $0 init" "Initialize a tenant and developer account"
  fi
  if [ -z "$1" -o "$1" = "details" ]; then
    print_command " $0 details" "Show tenant and developer account details"
  fi
  if [ -z "$1" -o "$1" = "build" ]; then
      print_command " $0 build" "Build a Docker image"
    fi
  if [ -z "$1" -o "$1" = "deploy" ]; then
    print_command " $0 deploy" "Deploy a new Docker image"
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

handler_ctl() {
  docker run --rm -it \
    --network=host \
    -v ${PWD}/.omglocaltestingctl:/opt/omgserversctl/.omgserversctl \
    -v ${PWD}/config.json:/opt/omgserversctl/config.json \
    omgservers/ctl:${OMGSERVERS_VERSION} $@
}

handler_details() {
  echo "$(date) Getting project details"

  TENANT=$(handler_ctl environment printVariable TENANT)
  PROJECT=$(handler_ctl environment printVariable PROJECT)
  STAGE=$(handler_ctl environment printVariable STAGE)
  DEVELOPER_USER=$(handler_ctl environment printVariable DEVELOPER_USER)
  DEVELOPER_PASSWORD=$(handler_ctl environment printVariable DEVELOPER_PASSWORD)

  if [ -z "${TENANT}" -o -z "${PROJECT}" -o -z "${STAGE}" -o -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    echo "ERROR: Project was not initialized" >&2
    exit 1
  fi

  echo "$(date) TENANT=\"${TENANT}\"",
  echo "$(date) TENANT_ALIAS=\"${TENANT_ALIAS}\""
  echo "$(date) PROJECT=\"${PROJECT}\""
  echo "$(date) PROJECT_ALIAS=\"${PROJECT_ALIAS}\""
  echo "$(date) STAGE=\"${STAGE}\""
  echo "$(date) STAGE_ALIAS=\"${STAGE_ALIAS}\""
  echo "$(date) DEVELOPER_USER=\"${DEVELOPER_USER}\""
  echo "$(date) DEVELOPER_PASSWORD=\"${DEVELOPER_PASSWORD}\""
}

handler_init() {
  echo "$(date) Using tenant alias, TENANT_ALIAS=\"${TENANT_ALIAS}\""
  echo "$(date) Using project alias, PROJECT_ALIAS=\"${PROJECT_ALIAS}\""
  echo "$(date) Using stage alias, STAGE_ALIAS=\"${STAGE_ALIAS}\""

  handler_ctl environment useLocalServer

  echo "$(date) Create a new tenant"

  handler_ctl support useCredentials "support" "support"
  handler_ctl support createToken
  handler_ctl support createTenant

  TENANT=$(handler_ctl environment printVariable TENANT)
  if [ -z "${TENANT}" ]; then
    echo "ERROR: TENANT was not found" >&2
    exit 1
  fi

  handler_ctl support createTenantAlias ${TENANT} ${TENANT_ALIAS}

  echo "$(date) Create a new project"

  handler_ctl support createProject ${TENANT_ALIAS}

  PROJECT=$(handler_ctl environment printVariable PROJECT)
  if [ -z "${PROJECT}" ]; then
    echo "ERROR: PROJECT was not found" >&2
    exit 1
  fi

  STAGE=$(handler_ctl environment printVariable STAGE)
  if [ -z "${STAGE}" ]; then
    echo "ERROR: STAGE was not found" >&2
    exit 1
  fi

  handler_ctl support createProjectAlias ${TENANT_ALIAS} ${PROJECT} ${PROJECT_ALIAS}
  handler_ctl support createStageAlias ${TENANT_ALIAS} ${STAGE} ${STAGE_ALIAS}

  echo "$(date) Create a new developer account"

  handler_ctl support createDeveloper

  DEVELOPER_USER=$(handler_ctl environment printVariable DEVELOPER_USER)
  if [ -z "${DEVELOPER_USER}" ]; then
    echo "ERROR: DEVELOPER_USER was not found" >&2
    exit 1
  fi

  DEVELOPER_PASSWORD=$(handler_ctl environment printVariable DEVELOPER_PASSWORD)
  if [ -z "${DEVELOPER_PASSWORD}" ]; then
    echo "ERROR: DEVELOPER_PASSWORD was not found" >&2
    exit 1
  fi

  echo "$(date) Configure developer permissions"

  handler_ctl support createTenantPermission ${TENANT_ALIAS} ${DEVELOPER_USER} TENANT_VIEWER
  handler_ctl support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} VERSION_MANAGER
  handler_ctl support createProjectPermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${DEVELOPER_USER} PROJECT_VIEWER
  handler_ctl support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} DEPLOYMENT_MANAGER
  handler_ctl support createStagePermission ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE} ${DEVELOPER_USER} STAGE_VIEWER

  echo "$(date) Login using developer account"

  handler_ctl developer useCredentials ${DEVELOPER_USER} ${DEVELOPER_PASSWORD}

  handler_details

  echo "$(date) All is done"
}

handler_reset() {
  handler_down
  handler_up
}

handler_build() {
  echo "$(date) Using docker image, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""

  docker build --build-arg OMGSERVERS_VERSION="${OMGSERVERS_VERSION}" -t "${DOCKER_IMAGE}" .
  echo "$(date) The image \"${DOCKER_IMAGE}\" has been built."
}

handler_deploy() {
  echo "$(date) Using docker image, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""

  echo "$(date) Get tenant details"

  TENANT=$(handler_ctl environment printVariable TENANT)
  PROJECT=$(handler_ctl environment printVariable PROJECT)
  STAGE=$(handler_ctl environment printVariable STAGE)
  DEVELOPER_USER=$(handler_ctl environment printVariable DEVELOPER_USER)
  DEVELOPER_PASSWORD=$(handler_ctl environment printVariable DEVELOPER_PASSWORD)

  if [ -z "${TENANT}" -o -z "${PROJECT}" -o -z "${STAGE}" -o -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    echo "ERROR: Project was not initialized" >&2
    exit 1
  fi

  echo "$(date) TENANT=\"${TENANT}\""
  echo "$(date) PROJECT=\"${PROJECT}\""
  echo "$(date) STAGE=\"${STAGE}\""
  echo "$(date) DEVELOPER_USER=\"${DEVELOPER_USER}\""
  echo "$(date) DEVELOPER_PASSWORD=\"${DEVELOPER_PASSWORD}\""

  echo "$(date) Login using developer account"

  handler_ctl developer createToken

  echo "$(date) Create a new version"

  handler_ctl developer createVersion ${TENANT} ${PROJECT} "./config.json"
  VERSION=$(handler_ctl environment printVariable VERSION)
  if [ -z "${VERSION}" -o "${VERSION}" == "null" ]; then
    echo "ERROR: VERSION was not found" >&2
    exit 1
  fi

  echo "$(date) Push docker image"

  TARGET_IMAGE="localhost:5000/omgservers/${TENANT}/${PROJECT}/universal:${VERSION}"
  docker login -u ${DEVELOPER_USER} -p ${DEVELOPER_PASSWORD} "localhost:5000"
  docker tag ${DOCKER_IMAGE} ${TARGET_IMAGE}
  docker push ${TARGET_IMAGE}

  echo "$(date) Deploy a new version"

  handler_ctl developer deployVersion ${TENANT} ${PROJECT} ${STAGE} ${VERSION}
  DEPLOYMENT=$(handler_ctl environment printVariable DEPLOYMENT)
  if [ -z "${DEPLOYMENT}" -o "${DEPLOYMENT}" == "null" ]; then
    echo "ERROR: DEPLOYMENT was not found" >&2
    exit 1
  fi

  echo "$(date) All is done"
}

if [ "$1" = "help" ]; then
  shift
  handler_help "$@"
  exit 0
fi

if [ "$1" = "up" ]; then
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
elif [ "$1" = "ctl" ]; then
  shift
  handler_ctl $@
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