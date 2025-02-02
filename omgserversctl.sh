#!/bin/bash
set -e
source omglocaltestingctl.env

docker run --rm -it \
  --network=host \
  -v ${PWD}/.omgserversctl:/opt/omgserversctl/.omgserversctl \
  -v ${PWD}/config.json:/opt/omgserversctl/config.json \
  omgservers/ctl:${OMGSERVERS_VERSION} $@

