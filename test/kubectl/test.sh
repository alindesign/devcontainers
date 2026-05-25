#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "kubectl present" command -v kubectl
check "kubectl version --client works" sh -c 'kubectl version --client=true 2>&1 | head -n1 | grep -iE "client"'
check "helm present (default on)" command -v helm
check "k9s present (default on)" command -v k9s
check "kubectx present (default on)" command -v kubectx
check "kubens present (default on)" command -v kubens

reportResults
