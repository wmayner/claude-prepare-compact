#!/usr/bin/env bash
# Save this session's prepare-compact handoff note.
#
#   write-handoff.sh <body_file>
#
# The note is stored under the session id, so sessions running in the same
# project never overwrite each other's notes. Writing again in the same session
# replaces the earlier note. hooks/load-handoff.sh loads it after the session's
# next compaction.

set -eu

body="${1:?usage: write-handoff.sh <body_file>}"
sid="${CLAUDE_CODE_SESSION_ID:?CLAUDE_CODE_SESSION_ID is not set; run this from a Claude Code session}"
dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/handoffs"

[ -s "$body" ] || { echo "ERROR: $body is missing or empty" >&2; exit 1; }
mkdir -p "$dir"
cp "$body" "$dir/$sid.md"
echo "WROTE $dir/$sid.md"
