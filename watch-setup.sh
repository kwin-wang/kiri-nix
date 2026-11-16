#!/usr/bin/env bash
# Open an issue when the upstream files that decide how Kiri sets up a Mac
# changed between two releases. Usage: watch-setup.sh v0.2.0 v0.2.1
set -euo pipefail

from=$1
to=$2
upstream=libracoder/kiri

# How Kiri sets up a Mac, and the names and paths that setup relies on.
watched=(
  crates/kiri/src/setup.rs
  crates/kiri/src/flavor.rs
  crates/kiri/src/update.rs
  packaging/README.md
)

pattern=$(printf '%s\n' "${watched[@]}" | jq -R . | jq -s .)
compare=$(gh api "repos/$upstream/compare/$from...$to")
changed=$(jq -r ".files[] | select(.filename as \$f | $pattern | index(\$f)) | \"- [\`\(.filename)\`](\(.blob_url)) (+\(.additions) -\(.deletions))\"" <<<"$compare")

# The compare API lists at most 300 files; past that a watched file may be
# missing from the list, so say so rather than stay quiet.
if [[ -z $changed && $(jq '.files | length' <<<"$compare") -ge 300 ]]; then
  changed="- More than 300 files changed, so the compare API could not tell whether the watched files did: ${watched[*]}"
fi

if [[ -z $changed ]]; then
  echo "no setup changes between $from and $to"
  exit 0
fi

title="Kiri $to changed its setup code"
if gh issue list --state all --search "\"$title\" in:title" --json number --jq '.[0].number' | grep -q .; then
  echo "issue already exists: $title"
  exit 0
fi

gh issue create --title "$title" --body "$(
  cat <<EOF
Upstream changed files that decide how \`kiri setup\` configures a Mac between $from and $to:

$changed

Full diff: https://github.com/$upstream/compare/$from...$to

Check whether configs built on this package still match, in particular:
- the LaunchAgent \`dev.kiri.daemon\` and how the app recognises it
- \`~/.kiri/bin\` and the PATH line written to shell profiles
- \`/var/run/docker.sock\` and \`kiri setup --docker-socket\`
- the in-app updater, which cannot replace a read-only Kiri.app
EOF
)"
