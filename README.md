# prepare-compact

A Claude Code plugin that helps a session keep its context across compaction.

When a conversation fills the context window, Claude Code compacts it and replaces everything so far with a summary. The summary records what happened, but it tends to drop the reasons for decisions, the options you ruled out, and the things still left to do. Then Claude starts asking questions you already answered.

Run `/prepare-compact` before you compact. Claude still has the whole conversation in view, and it writes itself a note with these sections:

- **Where we are:** the task, what is done, what is committed or only local, what is running, and the next step.
- **Decisions and why:** each decision with its reason, and the options turned down.
- **Open threads:** promises, questions waiting on you, and work left half done.
- **How the user works:** preferences and corrections you gave during the session.
- **Where to look:** details to look up in the full transcript instead of carrying them in the note.

Then type `/compact`. Right after the summary, a hook loads the note along with the path of the session's transcript. The transcript still holds everything from before the compaction, so Claude can search it for exact details.

You can steer the note with text after the command, for example `/prepare-compact focus on the migration plan; the logging work is done`.

## Install

In Claude Code:

```
/plugin marketplace add wmayner/prepare-compact
/plugin install prepare-compact@prepare-compact
```

The plugin needs `bash`, so it runs on macOS, Linux and WSL.

## How it works

- The skill saves the note to `~/.claude/handoffs/<session id>.md`. Notes are stored per session, so several sessions in the same project never overwrite each other's notes. Running `/prepare-compact` again in the same session replaces the note.
- A `SessionStart` hook runs after each compaction. If this session has a note, the hook prints it, Claude Code adds it to the context, and the note is renamed so it is never loaded twice.
- A note written more than two hours before the compaction is not loaded, since the work has probably moved on. Claude is told where the note is instead. Set `PREPARE_COMPACT_FRESH_MINUTES` to change the window.
- Used notes are kept in the same folder for 30 days, in case you want to reread one, and then deleted.

Nothing happens on automatic compactions unless you ran `/prepare-compact` first. To shape what the automatic summary keeps, add a section headed "Compact instructions" to your `CLAUDE.md`. The compactor reads it.

## Develop

```sh
bash tests/run.sh
claude plugin validate .
claude --plugin-dir .
```

## Credits

The note's sections and the pointer to the transcript are adapted from Gabriel Berzescu's [continuity](https://github.com/gabriel-berzescu/claude-continuity). That plugin writes a note at every compaction, including automatic ones, using Claude Code's early-access function hooks. This plugin uses only ordinary skills and command hooks, so it works on any Claude Code install.

## License

MIT
