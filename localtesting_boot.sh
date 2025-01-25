#!/bin/bash
set -e
set -o pipefail

./localtesting_init.sh
./localtesting_build.sh
./localtesting_deploy.sh