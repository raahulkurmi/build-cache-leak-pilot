#!/usr/bin/env bash
# Shared config for the pilot. Sourced by the numbered scripts.
set -euo pipefail

# Registry we OWN. Published to the host on 5000; reachable by the buildx
# container builder on the shared docker network as pilot-registry:5000.
NET=pilotnet
REG_CONTAINER=pilot-registry
REG_HOSTPORT=localhost:5000          # for host-side probing
REG_INNAME=pilot-registry:5000       # for buildx builder (same docker network)
BUILDER=pilot-builder

REPO_PREFIX=pilot                      # image path prefix
PATTERNS=(P1 P2 P3 P4 P5)
declare -A DOCKERFILE=(
  [P1]=dockerfiles/P1.copy-npmrc.Dockerfile
  [P2]=dockerfiles/P2.arg-env.Dockerfile
  [P3]=dockerfiles/P3.run-echo.Dockerfile
  [P4]=dockerfiles/P4.mount-secret.Dockerfile
  [P5]=dockerfiles/P5.copy-then-rm.Dockerfile
)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/.work"          # per-pattern build contexts + generated secrets (gitignored)
RESULTS="$ROOT/results"
mkdir -p "$WORK" "$RESULTS"
