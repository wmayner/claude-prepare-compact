#!/usr/bin/env bash
# Tests for write-handoff.sh and load-handoff.sh, run against a throwaway
# CLAUDE_CONFIG_DIR.  Usage: bash tests/run.sh

set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
write="$root/skills/prepare-compact/write-handoff.sh"
load="$root/hooks/load-handoff.sh"
export CLAUDE_CONFIG_DIR="$(mktemp -d)"
trap 'rm -rf "$CLAUDE_CONFIG_DIR"' EXIT
dir="$CLAUDE_CONFIG_DIR/handoffs"
failures=0

check() {
  if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failures=$((failures + 1)); fi
}

hook_input() {
  printf '{"session_id":"%s","transcript_path":"/t/%s.jsonl","cwd":"/p","hook_event_name":"SessionStart","source":"%s"}' "$1" "$1" "$2"
}

body="$CLAUDE_CONFIG_DIR/body.md"
printf '## Where we are\nPicnic at the lake.\n' > "$body"

out="$(CLAUDE_CODE_SESSION_ID=s1 bash "$write" "$body")"
check "write saves the note under the session id" '[ -f "$dir/s1.md" ] && [[ $out == WROTE* ]]'

CLAUDE_CODE_SESSION_ID=s2 bash "$write" "$body" > /dev/null
printf 'from stdin\n' | CLAUDE_CODE_SESSION_ID=s4 bash "$write" > /dev/null
check "write reads the note from standard input" 'grep -q "from stdin" "$dir/s4.md"'

check "a second session gets its own note" '[ -f "$dir/s1.md" ] && [ -f "$dir/s2.md" ]'

env -u CLAUDE_CODE_SESSION_ID bash "$write" "$body" > /dev/null 2>&1
check "write fails without a session id" '[ $? -ne 0 ]'

: > "$CLAUDE_CONFIG_DIR/empty.md"
CLAUDE_CODE_SESSION_ID=s3 bash "$write" "$CLAUDE_CONFIG_DIR/empty.md" > /dev/null 2>&1
check "write refuses an empty note" '[ $? -ne 0 ] && [ ! -f "$dir/s3.md" ]'

out="$(hook_input s1 startup | bash "$load")"
check "load ignores a session that did not start from compaction" '[ -z "$out" ] && [ -f "$dir/s1.md" ]'

out="$(hook_input s1 compact | bash "$load")"
check "load prints the note after compaction" '[[ $out == *"Picnic at the lake."* ]]'
check "load gives the transcript path" '[[ $out == *"/t/s1.jsonl"* ]]'
check "load marks the note consumed" '[ ! -f "$dir/s1.md" ] && ls "$dir"/s1.consumed-*.md > /dev/null 2>&1'
check "load leaves the other session's note alone" '[ -f "$dir/s2.md" ]'

out="$(hook_input s1 compact | bash "$load")"
check "a consumed note is not loaded again" '[ -z "$out" ]'

touch -t 202001010000 "$dir/s2.md"
out="$(hook_input s2 compact | bash "$load")"
check "a stale note is not loaded, and Claude is told where it is" '[[ $out != *"Picnic"* ]] && [[ $out == *"not loaded"* ]] && [ ! -f "$dir/s2.md" ]'

old="$dir/old.consumed-20200101T000000Z.md"
: > "$old" && touch -t 202001010000 "$old"
hook_input s9 compact | bash "$load" > /dev/null
check "consumed notes older than 30 days are deleted" '[ ! -f "$old" ]'

echo
[ "$failures" -eq 0 ] && echo "all tests passed" || { echo "$failures failed"; exit 1; }
