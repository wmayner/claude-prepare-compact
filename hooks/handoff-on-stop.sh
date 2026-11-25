#!/usr/bin/env bash
# Stop hook, off unless PREPARE_COMPACT_ON_STOP=1. When a large session ends a
# turn and its handoff note is missing or old, ask Claude to update the note
# first, so that a later compaction (including Claude Code's automatic one when
# an idle session's cache goes cold) has a recent note to load.
#
# Settings (environment variables; set them in a project's .claude/settings.json
# "env" to turn this on for that project only):
#   PREPARE_COMPACT_ON_STOP=1               turn the check on
#   PREPARE_COMPACT_ON_STOP_TOKENS=100000   only when the context holds at least this many tokens
#   PREPARE_COMPACT_ON_STOP_MINUTES=30      only when the note is older than this

[ "${PREPARE_COMPACT_ON_STOP:-}" = "1" ] || exit 0

input="$(cat)"

# Reads a string field from the hook's JSON input (an id and a path, which hold
# no escaped quotes).
field() {
  printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

# Claude is already continuing because of a Stop hook: never ask twice in a row.
printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

sid="$(field session_id)"
transcript="$(field transcript_path)"
[ -n "$sid" ] && [ -f "$transcript" ] || exit 0

min_tokens="${PREPARE_COMPACT_ON_STOP_TOKENS:-100000}"
max_minutes="${PREPARE_COMPACT_ON_STOP_MINUTES:-30}"
dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/handoffs"

# A note saved within the window, or one loaded after a compaction within it
# (load-handoff.sh renames it as consumed), counts as recent.
recent="$(find "$dir" -maxdepth 1 \( -name "$sid.md" -o -name "$sid.consumed-*.md" \) -mmin "-$max_minutes" 2>/dev/null | head -1)"
[ -z "$recent" ] || exit 0

# The context size is what the last main-conversation reply read: its input,
# cache-read and cache-write tokens. Only the end of the transcript is searched.
line="$(tail -n 300 "$transcript" | grep '"type":"assistant"' | grep '"usage":{"input_tokens"' \
  | grep -v '"isSidechain":true' | grep -v '"model":"<synthetic>"' | tail -1)"
[ -n "$line" ] || exit 0
usage="$(printf '%s' "$line" | sed 's/.*"usage":{"input_tokens"/"input_tokens"/')"
count() {
  n="$(printf '%s' "$usage" | grep -o "\"$1\":[0-9]*" | head -1 | sed 's/.*://')"
  echo "${n:-0}"
}
tokens=$(( $(count input_tokens) + $(count cache_read_input_tokens) + $(count cache_creation_input_tokens) ))
[ "$tokens" -ge "$min_tokens" ] || exit 0

if [ -f "$dir/$sid.md" ]; then state="more than $max_minutes minutes old"; else state="missing"; fi
reason="The context holds about $((tokens / 1000))k tokens and this session's handoff note is $state. Update it with the prepare-compact skill (/prepare-compact) now, so a compaction, including an automatic one while the session is idle, loads a recent note. Then end your turn with one short line; don't ask the user to type /compact."
printf '{"decision":"block","reason":"%s"}\n' "$reason"
