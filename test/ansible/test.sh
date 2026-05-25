#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "ansible present" command -v ansible
check "ansible-playbook present" command -v ansible-playbook
check "ansible-galaxy present" command -v ansible-galaxy
check "ansible-lint present (default on)" command -v ansible-lint
check "ansible --version works" sh -c 'ansible --version | head -n1 | grep -iE "ansible.*core"'
check "python3 present" command -v python3

reportResults
