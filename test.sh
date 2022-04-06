#!/bin/bash

set -euo pipefail

log_level=${1:-warn} # debug, info, warn, error, fatal

kitchen test --log-level="$log_level" --concurrency="$(nproc | awk '{printf "%d", $1 / 2}')"
