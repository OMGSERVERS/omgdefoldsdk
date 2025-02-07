#!/bin/sh
set -e
source .env

WORKING_DIR=${WORKING_DIR:-$PWD}

docker run --rm -it \
  --network=host \
  --env-file .env \
  -e WORKING_DIR=${WORKING_DIR} \
  -v ${WORKING_DIR}/.omgtoolctl:/opt/omgservers/.omgtoolctl \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  omgservers/tool:${OMGSERVERS_VERSION} $@
