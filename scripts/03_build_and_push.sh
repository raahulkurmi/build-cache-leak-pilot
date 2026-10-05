#!/usr/bin/env bash
# For each pattern: build the final image + push; export mode=min and mode=max
# registry caches to our own registry. Nothing here probes; see 04_probe.sh.
#
# Two independent axes:
#   cache mode      (--cache-to mode=min|max)   -> P1, P2, P3, P4, P5
#   provenance mode (--provenance=mode=min|max) -> P2b
# Provenance is pinned to mode=min for every build except P2b's leak build (max).
source "$(dirname "$0")/lib.sh"
declare -A MARK
while read -r P M; do MARK[$P]=$M; done < "$RESULTS/markers.txt"

for P in "${PATTERNS[@]}"; do
  CTX="$WORK/ctx-$P"
  IMG="$REG_INNAME/$REPO_PREFIX/${P,,}"
  SECRET="${MARK[$P]}"
  echo "=== $P -> $IMG ==="

  # Per-pattern inputs only. No shared build-args: the P4 control gets none.
  args=()
  case $P in
    P2)  args+=(--build-arg SECRET="$SECRET") ;;
    P2b) args+=(--build-arg LEAK_MARKER="$SECRET") ;;
    P4)  args+=(--secret id=tok,src="$CTX/secret.tok") ;;
  esac
  prov=mode=min; [ "$P" = P2b ] && prov=mode=max

  common=(buildx build --builder "$BUILDER" -f "$CTX/Dockerfile" "$CTX"
          "${args[@]}" --provenance="$prov")

  # 1) final image + push
  docker "${common[@]}" -t "$IMG:final" --push

  # 2) mode=min cache
  docker "${common[@]}" \
    --cache-to "type=registry,ref=$IMG:cache-min,mode=min" \
    -t "$IMG:final" --push

  # 3) mode=max cache
  docker "${common[@]}" \
    --cache-to "type=registry,ref=$IMG:cache-max,mode=max" \
    -t "$IMG:final" --push

  # 4) P2b provenance control: same inputs, provenance min, own tags
  #    (cache mode is irrelevant to this row; max for parity with the leak build)
  if [ "$P" = P2b ]; then
    docker buildx build --builder "$BUILDER" -f "$CTX/Dockerfile" "$CTX" \
      "${args[@]}" --provenance=mode=min \
      --cache-to "type=registry,ref=$IMG:cache-max-provmin,mode=max" \
      -t "$IMG:final-provmin" --push
  fi
done
echo "built + pushed final/cache-min/cache-max for all patterns (+ P2b final-provmin)"
