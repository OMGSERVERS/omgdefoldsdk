#!/bin/bash
set -e

docker run --rm -it \
  --network=omgservers \
  -v ${PWD}/.omgserversctl:/opt/omgserversctl/.omgserversctl \
  -v ${PWD}/config.json:/opt/omgserversctl/config.json \
  omgservers/ctl:1.0.0-SNAPSHOT $@
