#!/usr/bin/env bash
set -euo pipefail

# Use the public release URL directly. The Scout action downloads its
# executable through an unauthenticated GitHub API request on shared runners.
archive="$RUNNER_TEMP/docker-scout.tar.gz"
curl --fail --location --silent --show-error --retry 3 \
  https://github.com/docker/scout-cli/releases/download/v1.30.0/docker-scout_1.30.0_linux_amd64.tar.gz \
  --output "$archive"
echo "bd8d24896d2aa0f9e01d25830ac53cfd416a3254f8fbfce2cb10bcd7a1afe152  $archive" | sha256sum --check
plugins="${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins"
mkdir -p "$plugins"
tar -xzf "$archive" -C "$plugins" docker-scout
docker scout cves --only-severity critical,high --format sarif --output "$2" "$1"
