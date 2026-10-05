#!/usr/bin/env bash
# Generate synthetic, clearly-fake secrets and per-pattern build contexts.
source "$(dirname "$0")/lib.sh"
: > "$RESULTS/markers.txt"
for P in "${PATTERNS[@]}"; do
  HEX=$(openssl rand -hex 6)
  MARK="FAKE-SECRET-${P}-${HEX}-DO-NOT-USE"
  echo "${P} ${MARK}" >> "$RESULTS/markers.txt"
  CTX="$WORK/ctx-$P"; mkdir -p "$CTX"
  cp "$ROOT/${DOCKERFILE[$P]}" "$CTX/Dockerfile"
  # .npmrc for file-based patterns
  printf '//registry.example.test/:_authToken=%s\n' "$MARK" > "$CTX/.npmrc"
  # secret file for the mount control (P4)
  printf '%s\n' "$MARK" > "$CTX/secret.tok"
done
echo "generated synthetic markers -> $RESULTS/markers.txt (FAKE, local-only)"
