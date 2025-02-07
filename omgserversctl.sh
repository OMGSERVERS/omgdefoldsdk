#!/bin/sh
set -e
source .env

WORKING_DIR=${WORKING_DIR:-$PWD}

docker run --rm -it \
  --network=host \
  -v ${WORKING_DIR}/.omgserversctl:/opt/omgserversctl/.omgserversctl \
  -v ${WORKING_DIR}/config.json:/opt/omgserversctl/config.json:ro \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  omgservers/ctl:${OMGSERVERS_VERSION} $@
