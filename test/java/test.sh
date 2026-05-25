#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "java present" command -v java
check "javac present" command -v javac
check "java --version works" sh -c 'java --version | head -n1 | grep -E "[0-9]+\\."'
check "JAVA_HOME profile present" test -f /etc/profile.d/java.sh
check "mise binary present" command -v mise

reportResults
