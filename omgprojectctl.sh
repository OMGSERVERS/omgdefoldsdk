#!/bin/sh
set -e
set -o pipefail
export TZ=UTC
source .env

# INTERNAL

internal_print_command() {
  printf "  %-70s %s\n" "$1" "$2"
}

internal_ctl() {
  docker run --rm \
    --network=host \
    -e OMGTOOLCTL_WORKING_DIRECTORY=${PWD} \
    -v ${PWD}/.omgtoolctl:/opt/omgservers/.omgtoolctl \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /etc/resolv.conf:/etc/resolv.conf:ro \
    omgservers/tool:${OMGSERVERS_VERSION} $@
}

internal_useLocalServer() {
  internal_ctl installation useLocalServer
  internal_ctl installation admin createToken admin admin
  internal_ctl installation support createToken support support
}

# HANDLERS

handler_help() {
  echo "OMGPROJECT ctl, $(git branch --show-current)"
  echo "Usage:"
  if [ -z "$1" -o "$1" = "help" ]; then
    internal_print_command " $0 help" "Display this help message."
  fi
  if [ -z "$1" -o "$1" = "build" ]; then
    internal_print_command " $0 build" "Build a Docker image."
  fi
  if [ -z "$1" -o "$1" = "start" ]; then
    internal_print_command " $0 start" "Start the local environment."
  fi
  if [ -z "$1" -o "$1" = "init" ]; then
    internal_print_command " $0 init" "Initialize a project and developer account."
  fi
  if [ -z "$1" -o "$1" = "install" ]; then
    internal_print_command " $0 install" "Install a new version locally."
  fi
  if [ -z "$1" -o "$1" = "cleanup" ]; then
    internal_print_command " $0 cleanup" "Clean up the local server installation."
  fi
  if [ -z "$1" -o "$1" = "deploy" ]; then
    internal_print_command " $0 deploy <developer_user> <developer_password>" "Deploy a new version."
  fi
  if [ -z "$1" -o "$1" = "omgtoolctl" ]; then
    internal_print_command " $0 omgtoolctl <command>" "Run the command through omgtoolctl."
  fi
}

handler_build() {
  echo "$(date) [OMGPROJECTCTL/build] (${TENANT_ALIAS}/${PROJECT_ALIAS}) Using, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""

  docker build -t "${DOCKER_IMAGE}" .
  echo "$(date) [OMGPROJECTCTL/build] (${TENANT_ALIAS}/${PROJECT_ALIAS}) The image \"${DOCKER_IMAGE}\" has been built."
}

handler_start() {
  internal_ctl installation useLocalServer
  internal_ctl localtesting reset
  internal_ctl installation ctl environment reset
}

handler_init() {
  internal_useLocalServer
  internal_ctl installation support createTenant ${TENANT_ALIAS}
  internal_ctl installation support createProject ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE_ALIAS}
}

handler_install() {
  internal_useLocalServer

  DEVELOPER_USER=$(internal_ctl installation ctl environment printVariable DEVELOPER_USER)
  if [ -z "${DEVELOPER_USER}" ]; then
    echo "$(date) [OMGPROJECTCTL/install] (${TENANT_ALIAS}/${PROJECT_ALIAS}) ERROR: DEVELOPER_USER was not found"
    exit 1
  fi

  DEVELOPER_PASSWORD=$(internal_ctl installation ctl environment printVariable DEVELOPER_PASSWORD)
  if [ -z "${DEVELOPER_PASSWORD}" ]; then
    echo "$(date) [OMGPROJECTCTL/install] (${TENANT_ALIAS}/${PROJECT_ALIAS}) ERROR: DEVELOPER_PASSWORD was not found"
    exit 1
  fi

  internal_ctl installation developer deployVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE_ALIAS} "${DEVELOPER_USER}" "${DEVELOPER_PASSWORD}"
}

handler_cleanup() {
  internal_useLocalServer
  internal_ctl installation ctl support deleteTenant ${TENANT_ALIAS}
  internal_ctl installation ctl environment reset
}

handler_deploy() {
  DEVELOPER_USER=$1
  DEVELOPER_PASSWORD=$2

  if [ -z "${DEVELOPER_USER}" -o -z "${DEVELOPER_PASSWORD}" ]; then
    handler_help "deploy"
    exit 1
  fi

  echo "$(date) [OMGPROJECTCTL/deploy] (${TENANT_ALIAS}/${PROJECT_ALIAS}) Using, DEVELOPER_USER=\"${DEVELOPER_USER}\"" >&2

  internal_ctl installation useCustomUrl installation ${INSTALLATION_URL}
  internal_ctl installation developer deployVersion ${TENANT_ALIAS} ${PROJECT_ALIAS} ${STAGE_ALIAS} ${DEVELOPER_USER} ${DEVELOPER_PASSWORD}
}

handler_omgtoolctl() {
  internal_ctl $@
}

ARG=$1
if [ -z "${ARG}" ]; then
  handler_help
  exit 0
else
  shift

  if [ "${ARG}" = "help" ]; then
    handler_help "$*"
  elif [ "${ARG}" = "build" ]; then
    handler_build $@
  elif [ "${ARG}" = "start" ]; then
    handler_start $@
  elif [ "${ARG}" = "init" ]; then
    handler_init $@
  elif [ "${ARG}" = "install" ]; then
    handler_install $@
  elif [ "${ARG}" = "cleanup" ]; then
    handler_cleanup $@
  elif [ "${ARG}" = "deploy" ]; then
    handler_deploy $@
  elif [ "${ARG}" = "omgtoolctl" ]; then
    handler_omgtoolctl $@
  else
    handler_help
    exit 1
  fi
fi