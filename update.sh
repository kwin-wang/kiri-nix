#!/usr/bin/env bash
# Point sources.json at the latest libracoder/kiri release (or the version given).
set -euo pipefail

cd "$(dirname "$0")"

repo=libracoder/kiri
if [[ $# -gt 0 ]]; then
  version=${1#v}
else
  version=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name | ltrimstr("v")')
fi

current=$(jq -r .version sources.json)
if [[ $version == "$current" ]]; then
  echo "kiri is already at $version"
  exit 0
fi

prefetch() {
  local url=$1
  nix store prefetch-file --json "$url" | jq -r .hash
}

base="https://github.com/$repo/releases/download/v$version"
arm_url="$base/Kiri-$version-arm64.tar.gz"
intel_url="$base/Kiri-$version-x86_64.tar.gz"
arm_hash=$(prefetch "$arm_url")
intel_hash=$(prefetch "$intel_url")

jq -n \
  --arg version "$version" \
  --arg arm_url "$arm_url" --arg arm_hash "$arm_hash" \
  --arg intel_url "$intel_url" --arg intel_hash "$intel_hash" \
  '{
    version: $version,
    "aarch64-darwin": {url: $arm_url, hash: $arm_hash},
    "x86_64-darwin": {url: $intel_url, hash: $intel_hash}
  }' >sources.json

echo "kiri $current -> $version"
