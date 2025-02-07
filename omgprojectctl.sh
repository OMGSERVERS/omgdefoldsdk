#!/bin/sh
set -e
source .env

# INTERNAL

internal_print_command() {
  printf "  %-30s %s\n" "$1" "$2"
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
}

handler_build() {
  echo "$(date) Using, DOCKER_IMAGE=\"${DOCKER_IMAGE}\""

  docker build -t "${DOCKER_IMAGE}" .
  echo "$(date) The image \"${DOCKER_IMAGE}\" has been built."
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
  else
    handler_help
    exit 1
  fi
fi
