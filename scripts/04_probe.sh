#!/usr/bin/env bash
# Probe ONLY artifacts we pushed to our own registry for each pattern's marker.
# Emits results/matrix.json and results/matrix.md.
source "$(dirname "$0")/lib.sh"
declare -A MARK
while read -r P M; do MARK[$P]=$M; done < "$RESULTS/markers.txt"
REG="http://$REG_HOSTPORT/v2"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# grep every blob referenced (recursively) by a tag for the marker.
scan_tag() { # repo tag marker -> prints RECOVERABLE / NOT_RECOVERABLE
  local repo="$1" tag="$2" marker="$3" hit=0
  local acc='application/vnd.oci.image.index.v1+json,application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.docker.distribution.manifest.v2+json'
  mapfile -t digs < <(
    curl -fsSL -H "Accept: $acc" "$REG/$repo/manifests/$tag" 2>/dev/null \
    | jq -r '.. | objects | .digest? // empty' | sort -u)
  for d in "${digs[@]}"; do
    curl -fsSL "$REG/$repo/blobs/$d" -o "$tmp/blob" 2>/dev/null || continue
    # config/manifest json: grep raw; layer blobs: try gunzip|tar then raw
    if grep -qa "$marker" "$tmp/blob"; then hit=1; break; fi
    if tar -tzf "$tmp/blob" >/dev/null 2>&1; then
      if tar -xzf "$tmp/blob" -O 2>/dev/null | grep -qa "$marker"; then hit=1; break; fi
    fi
  done
  [ "$hit" = 1 ] && echo RECOVERABLE || echo NOT_RECOVERABLE
}

echo '{}' > "$RESULTS/matrix.json"
{ echo "| Pattern | Final image | mode=min cache | mode=max cache |";
  echo "|---------|:-----------:|:--------------:|:--------------:|"; } > "$RESULTS/matrix.md"

for P in "${PATTERNS[@]}"; do
  repo="$REPO_PREFIX/${P,,}"; m="${MARK[$P]}"
  f=$(scan_tag "$repo" final "$m")
  n=$(scan_tag "$repo" cache-min "$m")
  x=$(scan_tag "$repo" cache-max "$m")
  echo "| $P | $f | $n | $x |" >> "$RESULTS/matrix.md"
  jq --arg p "$P" --arg f "$f" --arg n "$n" --arg x "$x" \
     '.[$p]={final:$f,cache_min:$n,cache_max:$x}' \
     "$RESULTS/matrix.json" > "$tmp/j" && mv "$tmp/j" "$RESULTS/matrix.json"
done
echo "wrote $RESULTS/matrix.md and matrix.json"; cat "$RESULTS/matrix.md"
