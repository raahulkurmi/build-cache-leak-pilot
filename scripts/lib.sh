#!/usr/bin/env bash
# Shared config for the pilot. Sourced by the numbered scripts.
set -euo pipefail

# declare -A, ${var,,}, mapfile and empty "${arr[@]}" under set -u need bash >= 5.
# macOS /bin/bash is 3.2: `brew install bash` and make sure `env bash` resolves to it.
if [ "${BASH_VERSINFO[0]}" -lt 5 ]; then
  echo "bash >= 5 required, got $BASH_VERSION ($BASH). brew install bash" >&2; exit 1
fi

# Registry we OWN. Published to the host on 5000; reachable by the buildx
# container builder on the shared docker network as pilot-registry:5000.
NET=pilotnet
REG_CONTAINER=pilot-registry
REG_HOSTPORT=localhost:5000          # for host-side probing
REG_INNAME=pilot-registry:5000       # for buildx builder (same docker network)
BUILDER=pilot-builder

REPO_PREFIX=pilot                      # image path prefix
PATTERNS=(P1 P2 P2b P3 P4 P5)
declare -A DOCKERFILE=(
  [P1]=dockerfiles/P1.copy-npmrc.Dockerfile
  [P2]=dockerfiles/P2.arg-env.Dockerfile
  [P2b]=dockerfiles/P2b.arg-only.Dockerfile
  [P3]=dockerfiles/P3.run-echo.Dockerfile
  [P4]=dockerfiles/P4.mount-secret.Dockerfile
  [P5]=dockerfiles/P5.copy-then-rm.Dockerfile
)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/.work"          # per-pattern build contexts + generated secrets (gitignored)
RESULTS="$ROOT/results"
mkdir -p "$WORK" "$RESULTS"
