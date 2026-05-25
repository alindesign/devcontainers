#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "opam present" command -v opam
check "ocaml present" command -v ocaml
check "ocaml --version works" sh -c 'ocaml --version | grep -E "[0-9]+\\."'
check "dune present" command -v dune
check "OPAMROOT profile present" test -f /etc/profile.d/opam.sh

reportResults
