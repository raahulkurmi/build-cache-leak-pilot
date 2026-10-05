#!/usr/bin/env bash
# For each pattern: build the final image + push; export mode=min and mode=max
# registry caches to our own registry. Nothing here probes; see 04_probe.sh.
source "$(dirname "$0")/lib.sh"
declare -A MARK
while read -r P M; do MARK[$P]=$M; done < "$RESULTS/markers.txt"

for P in "${PATTERNS[@]}"; do
  CTX="$WORK/ctx-$P"
  IMG="$REG_INNAME/$REPO_PREFIX/${P,,}"
  SECRET="${MARK[$P]}"
  echo "=== $P -> $IMG ==="

  common=(buildx build --builder "$BUILDER" -f "$CTX/Dockerfile" "$CTX"
          --build-arg SECRET="$SECRET"
          --secret id=tok,src="$CTX/secret.tok")

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
done
echo "built + pushed final/cache-min/cache-max for all patterns"
