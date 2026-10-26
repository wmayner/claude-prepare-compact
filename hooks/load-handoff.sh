#!/usr/bin/env bash
# SessionStart hook (source "compact"). If prepare-compact saved a handoff note
# for this session recently, print it, so Claude Code adds it to the context
# right after the compaction summary. The note is then renamed as consumed, so
# it is loaded only once. A note older than the freshness window is not loaded,
# since the work has likely moved on; Claude is told where it is instead.

input="$(cat)"

# Reads a string field from the hook's JSON input. The fields used here are an
# id, a fixed word and a path, so they hold no escaped quotes.
field() {
  printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

[ "$(field source)" = "compact" ] || exit 0
sid="$(field session_id)"
[ -n "$sid" ] || exit 0

dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/handoffs"
note="$dir/$sid.md"
fresh_minutes="${PREPARE_COMPACT_FRESH_MINUTES:-120}"

# Consumed notes are kept for a month in case you want to reread one.
find "$dir" -name '*.consumed-*.md' -mtime +30 -delete 2>/dev/null

[ -f "$note" ] || exit 0
consumed="$dir/$sid.consumed-$(date -u +%Y%m%dT%H%M%SZ).md"

if [ -z "$(find "$note" -mmin "-$fresh_minutes" 2>/dev/null)" ]; then
  mv "$note" "$consumed"
  echo "A /prepare-compact handoff note for this session was written more than $fresh_minutes minutes before this compaction, so it was not loaded. It may be out of date; it is at $consumed."
  exit 0
fi

transcript="$(field transcript_path)"
echo "Handoff note written by /prepare-compact just before this compaction. Continue from here."
if [ -n "$transcript" ]; then
  echo "The full transcript from before the compaction is at $transcript (one JSON object per line). Search it for anything listed under \"Where to look\"."
fi
echo
cat "$note"
mv "$note" "$consumed"
