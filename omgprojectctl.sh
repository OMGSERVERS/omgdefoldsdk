#!/bin/sh
set -e
set -o pipefail
export TZ=UTC

# Environment Variables:
# OMG_DOCKER_IMAGE is "omgservers/localtesting:latest" by default

OMG_DOCKER_IMAGE=${OMG_DOCKER_IMAGE:-"omgservers/localtesting:latest"}

# INTERNAL

internal_print_command() {
  printf "  %-50s %s\n" "$1" "$2"
}

# HANDLERS

handler_help() {
  echo "OMGPROJECT ctl, $(git branch --show-current)"
  echo "Usage: $0"
  if [ -z "$1" -o "$1" = "help" ]; then
    internal_print_command " help <command>" "Display this help message."
  fi
  if [ -z "$1" -o "$1" = "build" ]; then
    internal_print_command " build" "Build a Docker image."
  fi
}

handler_build() {
  DOCKER_IMAGE=${OMG_DOCKER_IMAGE}

  echo "$(date) [OMGPROJECTCTL/build] Using, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""

  docker build -t "${DOCKER_IMAGE}" .
  echo "$(date) [OMGPROJECTCTL/build] The image \"${DOCKER_IMAGE}\" has been built."
}

# MAIN

ARG=$1
if [ -z "${ARG}" ]; then
  handler_help
  exit 1
else
  shift
  if [ "${ARG}" = "help" ]; then
    handler_help "$*"
  elif [ "${ARG}" = "build" ]; then
    handler_build $@
  else
    handler_help
    exit 1
  fi
fi