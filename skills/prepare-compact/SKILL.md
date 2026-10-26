---
name: prepare-compact
description: Prepare for compaction by writing a handoff note that is loaded automatically right after the compaction summary
---

$ARGUMENTS

---

You are about to compact the conversation and continue afterward. Compaction replaces the conversation with a summary, and summaries keep what happened but tend to lose why. Your job now, with the whole conversation still in view, is to write the note you will read right after the compaction, so the work continues as the same collaboration instead of starting over from a summary. If there is text above the line, it is the user's guidance for this note; follow it.

## Write the note

Write it in the first person, as notes to yourself, in plain markdown, with these sections:

### Where we are
The current task and its state: what is done, what is committed or pushed and what is only local, and any running processes or background jobs (what each does and how it reports back). End with the immediate next step, as agreed with the user.

### Decisions and why
Each decision with its reason and who made it, and the options turned down and why. Quote the user's own short words where they matter.

### Open threads
Promises you made, questions waiting on the user, things to check, and anything left half done.

### How the user works
Preferences and corrections the user gave in this session, and lessons learned the hard way. Keep the lesson, not the story of the attempt.

### Where to look
Details worth looking up in the full transcript instead of copying here, such as exact quotes, numbers, long lists or file contents. For each, give a few words to search for. The transcript stays on disk, and its path is given to you along with this note.

Leave out raw tool output, file contents, step-by-step logs, and anything the repository or its git history already records. Keep it under about 1,500 words. Make it self-contained: it is added on top of the compaction summary, so anything that must survive the compaction goes here.

## Save it

Save the note by passing it to the helper on standard input, in a single Bash command:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/prepare-compact/write-handoff.sh" <<'END_OF_HANDOFF'
<the note>
END_OF_HANDOFF
```

It prints `WROTE <path>` when the note is saved. Tell the user it is ready and that they only need to type `/compact`, with no argument; the note is loaded right after the summary. Running `/prepare-compact` again before compacting replaces the note. A note written more than two hours before the compaction is not loaded, because the work has likely moved on.
