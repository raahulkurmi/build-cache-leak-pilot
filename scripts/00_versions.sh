#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
{
  echo "# Captured $(date -u +%FT%TZ)"
  echo "## host";            uname -a
  echo "## bash";            echo "$BASH_VERSION ($BASH)"
  echo "## docker";          docker version
  echo "## buildx";          docker buildx version
  echo "## buildx inspect";  docker buildx inspect "$BUILDER" 2>/dev/null || docker buildx inspect
  echo "## registry image";  docker image inspect registry:2 --format '{{.RepoDigests}}' 2>/dev/null || echo "registry:2 not pulled yet"
  echo "## gh";              gh --version
} > "$RESULTS/versions.txt"
echo "wrote $RESULTS/versions.txt"
