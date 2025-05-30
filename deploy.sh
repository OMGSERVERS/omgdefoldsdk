#!/bin/bash
./omgserversctl.sh developer localtesting deploy-version \
  -c config.json \
  -i omgservers/localtesting:latest \
  -s deployment.json
