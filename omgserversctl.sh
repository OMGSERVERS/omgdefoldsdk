#!/bin/bash
set -e
source omglocalctl.env

docker run --rm \
  --network=host \
  -v ${PWD}/.omgserversctl:/opt/omgserversctl/.omgserversctl \
  -v ${PWD}/config.json:/opt/omgserversctl/config.json:ro \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  omgservers/ctl:${OMGSERVERS_VERSION} $@
