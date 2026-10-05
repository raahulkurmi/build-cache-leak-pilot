#!/usr/bin/env bash
# Part 2: GitHub code-search COUNTS ONLY (total_count). No names, no contents stored.
# Throttled under the authenticated code-search limit.
source "$(dirname "$0")/lib.sh"
out="$RESULTS/prevalence.json"
date_utc=$(date -u +%FT%TZ)
ghver=$(gh --version | head -1)

declare -A Q=(
  [q1_max_registry_cache]='"cache-to" "type=registry" "mode=max" path:.github/workflows'
  [q2_any_registry_cache]='"cache-to" "type=registry" path:.github/workflows'
  [q3_gha_cache]='"cache-to" "type=gha" path:.github/workflows'
  [q4_target_push]='"target:" "push: true" path:.github/workflows'
)

echo "{" > "$out"
echo "  \"queried_at\": \"$date_utc\", \"gh\": \"$ghver\", \"counts\": {" >> "$out"
first=1
for k in q1_max_registry_cache q2_any_registry_cache q3_gha_cache q4_target_push; do
  q="${Q[$k]}"
  n=$(gh api -X GET search/code -f q="$q" --jq '.total_count' 2>/dev/null || echo null)
  [ $first -eq 0 ] && echo "," >> "$out"; first=0
  printf '    "%s": {"query": %s, "total_count": %s}' "$k" "$(jq -Rn --arg s "$q" '$s')" "$n" >> "$out"
  sleep 7   # stay under ~10 code-search req/min
done
echo "" >> "$out"; echo "  }" >> "$out"; echo "}" >> "$out"
echo "wrote $out (counts only)"; cat "$out"
