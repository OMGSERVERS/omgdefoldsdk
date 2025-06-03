#!/bin/bash
./omgserversctl.sh developer localtesting deploy-version \
  -c config.json \
  -i omgservers/omgdefoldsdk:latest \
  -s deployment.json \
  omgservers \
  omgdefoldsdk \
  default
