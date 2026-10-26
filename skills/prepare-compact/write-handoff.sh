#!/usr/bin/env bash
# Save this session's prepare-compact handoff note.
#
#   write-handoff.sh [note_file]
#
# Reads the note from note_file, or from standard input if no file is given.
# The note is stored under the session id, so sessions running in the same
# project never overwrite each other's notes. Writing again in the same session
# replaces the earlier note. hooks/load-handoff.sh loads it after the session's
# next compaction.

set -eu

sid="${CLAUDE_CODE_SESSION_ID:?CLAUDE_CODE_SESSION_ID is not set; run this from a Claude Code session}"
dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/handoffs"

mkdir -p "$dir"
tmp="$(mktemp "$dir/.$sid.XXXXXX")"
cat "${1:-/dev/stdin}" > "$tmp"
[ -s "$tmp" ] || { rm -f "$tmp"; echo "ERROR: the note is empty" >&2; exit 1; }
mv "$tmp" "$dir/$sid.md"
echo "WROTE $dir/$sid.md"
