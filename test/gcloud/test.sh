#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "gcloud binary present" command -v gcloud
check "gcloud --version works" sh -c 'gcloud --version 2>&1 | head -n1 | grep -E "Google Cloud SDK"'

reportResults
