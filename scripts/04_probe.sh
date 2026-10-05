#!/usr/bin/env bash
# Probe ONLY artifacts we pushed to our own registry for each pattern's marker.
# Emits results/matrix.json and results/matrix.md.
#
# Verdicts: RECOVERABLE | NOT_RECOVERABLE | ABSENT (nothing of that class exists,
# e.g. no attestation attached) | PROBE_ERROR (a ref or blob could not be fetched) |
# n/a (location not built for this pattern). A fetch failure is never NOT_RECOVERABLE.
source "$(dirname "$0")/lib.sh"
declare -A MARK
while read -r P M; do MARK[$P]=$M; done < "$RESULTS/markers.txt"
REG="http://$REG_HOSTPORT/v2"
ACC='application/vnd.oci.image.index.v1+json,application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.docker.distribution.manifest.v2+json'
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# walk repo ref kind -> prints "<class> <digest>" for every blob reachable from ref.
#   kind image : index -> child manifests via /manifests; attestation-manifest children
#                are walked as kind attest. Image manifest -> "config" + "layer".
#   kind attest: every blob of the attestation manifest -> "attest".
#   kind cache : every blob of the cache export -> "cache", plus the layers the
#                cacheconfig references (.layers[].blob).
# Unfetchable refs print "error <ref>".
walk() {
  local repo="$1" ref="$2" kind="$3" m
  if ! m=$(curl -fsSL -H "Accept: $ACC" "$REG/$repo/manifests/$ref" 2>/dev/null); then
    echo "error $ref"; return 0
  fi
  if jq -e 'has("manifests")' <<<"$m" >/dev/null; then
    jq -r '.manifests[] | [.digest, (.mediaType // ""),
             (.annotations["vnd.docker.reference.type"] // "-")] | @tsv' <<<"$m" |
    while IFS=$'\t' read -r d mt rt; do
      if [ "$kind" = cache ]; then
        case $mt in
          *manifest*|*index*) walk "$repo" "$d" cache ;;
          *cacheconfig*)
            echo "cache $d"
            if curl -fsSL "$REG/$repo/blobs/$d" -o "$tmp/cc" 2>/dev/null; then
              jq -r '.layers[]?.blob // empty' "$tmp/cc" | sed 's/^/cache /' \
                || echo "error $d"
            else echo "error $d"; fi ;;
          *) echo "cache $d" ;;
        esac
      elif [ "$rt" = attestation-manifest ]; then walk "$repo" "$d" attest
      else walk "$repo" "$d" "$kind"; fi
    done
  else
    case $kind in
      attest) jq -r '.config.digest, .layers[].digest' <<<"$m" | sed 's/^/attest /' ;;
      cache)  jq -r '.config.digest, .layers[].digest' <<<"$m" | sed 's/^/cache /' ;;
      *)      jq -r '.config.digest' <<<"$m" | sed 's/^/config /'
              jq -r '.layers[].digest' <<<"$m" | sed 's/^/layer /' ;;
    esac
  fi
}

# blob_has repo digest marker -> 0 hit, 1 miss, 2 fetch/decode error.
# Path-agnostic: greps raw bytes, the gzip/zstd-decoded stream (tar content is plain
# inside it), and a base64 DSSE .payload if present. Never binds to a SLSA JSON path.
blob_has() {
  local repo="$1" d="$2" marker="$3" f="$tmp/blob"
  curl -fsSL "$REG/$repo/blobs/$d" -o "$f" 2>/dev/null || return 2
  grep -qa -- "$marker" "$f" && return 0
  case $(head -c4 "$f" | od -An -tx1 | tr -d ' \n') in
    1f8b*)    gzip -dc "$f" 2>/dev/null | grep -qa -- "$marker" && return 0 ;;
    28b52ffd) command -v zstd >/dev/null || return 2
              zstd -dc "$f" 2>/dev/null | grep -qa -- "$marker" && return 0 ;;
  esac
  if jq -er '.payload // empty' "$f" >/dev/null 2>&1; then
    jq -r '.payload' "$f" | base64 -d 2>/dev/null | grep -qa -- "$marker" && return 0
  fi
  return 1
}

# verdict repo class marker <walkfile> -> verdict over all blobs of that class
verdict() {
  local repo="$1" class="$2" marker="$3" wf="$4" d rc err=0 n=0
  grep -q '^error ' "$wf" && err=1
  while read -r d; do
    n=$((n+1)); rc=0; blob_has "$repo" "$d" "$marker" || rc=$?
    [ "$rc" = 0 ] && { echo RECOVERABLE; return; }
    [ "$rc" = 2 ] && err=1
  done < <(awk -v c="$class" '$1==c {print $2}' "$wf" | sort -u)
  if [ "$err" = 1 ]; then echo PROBE_ERROR
  elif [ "$n" = 0 ]; then echo ABSENT
  else echo NOT_RECOVERABLE; fi
}

probe() { # repo ref kind class marker
  walk "$1" "$2" "$3" > "$tmp/walk"; verdict "$1" "$4" "$5" "$tmp/walk"
}

echo '{}' > "$RESULTS/matrix.json"
{ echo "| Pattern | Final config | Final layers | mode=min cache | mode=max cache | Prov-attest (max) | Prov-attest (min) |";
  echo "|---------|:---:|:---:|:---:|:---:|:---:|:---:|"; } > "$RESULTS/matrix.md"

for P in "${PATTERNS[@]}"; do
  repo="$REPO_PREFIX/${P,,}"; m="${MARK[$P]}"
  fc=$(probe "$repo" final image config "$m")
  fl=$(probe "$repo" final image layer "$m")
  cn=$(probe "$repo" cache-min cache cache "$m")
  cx=$(probe "$repo" cache-max cache cache "$m")
  if [ "$P" = P2b ]; then   # :final = provenance max, :final-provmin = control
    ax=$(probe "$repo" final image attest "$m")
    an=$(probe "$repo" final-provmin image attest "$m")
  else                      # all other patterns are pinned to provenance min
    ax=n/a
    an=$(probe "$repo" final image attest "$m")
  fi
  echo "| $P | $fc | $fl | $cn | $cx | $ax | $an |" >> "$RESULTS/matrix.md"
  jq --arg p "$P" --arg fc "$fc" --arg fl "$fl" --arg cn "$cn" --arg cx "$cx" \
     --arg ax "$ax" --arg an "$an" \
     '.[$p]={final_config:$fc,final_layers:$fl,cache_min:$cn,cache_max:$cx,
             attest_provmax:$ax,attest_provmin:$an}' \
     "$RESULTS/matrix.json" > "$tmp/j" && mv "$tmp/j" "$RESULTS/matrix.json"
done
echo "wrote $RESULTS/matrix.md and matrix.json"; cat "$RESULTS/matrix.md"
