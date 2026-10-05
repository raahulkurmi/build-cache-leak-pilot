#!/usr/bin/env bash
# Generate synthetic, clearly-fake secrets and per-pattern build contexts.
source "$(dirname "$0")/lib.sh"
: > "$RESULTS/markers.txt"
for P in "${PATTERNS[@]}"; do
  HEX=$(openssl rand -hex 6)
  MARK="FAKE-SECRET-${P}-${HEX}-DO-NOT-USE"
  echo "${P} ${MARK}" >> "$RESULTS/markers.txt"
  CTX="$WORK/ctx-$P"; mkdir -p "$CTX"
  # __MARKER__ is the baked literal for P3; no-op for the other Dockerfiles
  sed "s/__MARKER__/$MARK/g" "$ROOT/${DOCKERFILE[$P]}" > "$CTX/Dockerfile"
  # per-pattern inputs only: each context holds just the channel under test
  case $P in
    P1|P5) printf '//registry.example.test/:_authToken=%s\n' "$MARK" > "$CTX/.npmrc" ;;
    P4)    printf '%s\n' "$MARK" > "$CTX/secret.tok" ;;  # mount control
  esac
done
echo "generated synthetic markers -> $RESULTS/markers.txt (FAKE, local-only)"
