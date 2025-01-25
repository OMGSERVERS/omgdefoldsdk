#!/bin/bash
set -e
set -o pipefail
source ./localtesting_vars.sh

./localtesting_down.sh
./localtesting_up.sh