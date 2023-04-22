#!/bin/bash

set -euxo pipefail

target=${1}

cinc-auditor exec ./profile/controls/ -t "ssh://${target}" --show-progress
