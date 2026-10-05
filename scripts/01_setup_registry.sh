#!/usr/bin/env bash
# Stand up a local registry we own + a buildx builder that can reach it over http.
source "$(dirname "$0")/lib.sh"

docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET"

if ! docker inspect "$REG_CONTAINER" >/dev/null 2>&1; then
  docker run -d --name "$REG_CONTAINER" --network "$NET" -p 5000:5000 \
    --restart=unless-stopped registry:2
else
  docker start "$REG_CONTAINER" >/dev/null
fi

# buildkitd config allowing the insecure (http) local registry
BK_CFG="$WORK/buildkitd.toml"
cat > "$BK_CFG" <<CFG
[registry."$REG_INNAME"]
  http = true
  insecure = true
CFG

if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  docker buildx create --name "$BUILDER" --driver docker-container \
    --driver-opt network="$NET" --config "$BK_CFG" --bootstrap
fi
docker buildx inspect "$BUILDER" >/dev/null
echo "registry + builder ready ($REG_INNAME inside net, $REG_HOSTPORT on host)"
