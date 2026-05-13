---
name: remove-wiki
description: Permanently delete a sub-wiki directory under the top-level llm-wiki/ root. Use only when the user explicitly asks to "remove", "delete", "drop", "지워", "삭제해" a named wiki. Destructive and irreversible — requires the user to re-type the wiki name as a second-line confirmation before any rm. If the removed wiki is the currently attached one, also clears <ROOT>/.claude/state/attached-wiki.
---

# remove-wiki

## Contract

Delete one named sub-wiki — the whole `<ROOT>/<name>/` tree — after an explicit double-confirmation. There is no undo other than `git`. Never bulk-remove. Never proceed without the user re-typing the exact name. Always clear attach state if the removed wiki was the attached one.

## When To Use

- The user names a wiki and asks to remove, delete, drop, purge it.
- The user typed `/remove-wiki <name>` directly.

## When Not To Use

- The user only wants to clear files inside a wiki — do a targeted edit.
- The user wants to detach, not delete — use `detach-wiki`.
- The user did not name a specific wiki — run `list-wikis` and ask. Never guess.

## How To Run — Two Turns

This is a deliberately two-turn flow so the user has a chance to abort.

### Turn 1: preview

```bash
bash "$SKILL_DIR/preview.sh" "$TARGET" [ROOT]
```

Prints the path, file/dir counts, layer badges, and attach status. Then ask the user, in one sentence, to **type the wiki name again exactly** to confirm. Stop and wait. Do not run `apply.sh` in the same turn.

### Turn 2: apply

In the next user turn, take the user's typed reply as `$TYPED` and run:

```bash
bash "$SKILL_DIR/apply.sh" "$TARGET" "$TYPED" [ROOT]
```

The script:
- Trims only outer whitespace from `$TYPED`, then compares byte-for-byte to `$TARGET`.
- On mismatch, prints `aborted: confirmation did not match` and exits 1 (no deletion).
- On match, `rm -rf -- "$ROOT/$TARGET"` and prints `removed: $TARGET`.
- If the removed wiki was attached, also clears the state file and prints `detached: $TARGET (was attached)`.

### When To Abort Without Calling apply.sh

If the user's reply is clearly a cancel — "no", "취소", "stop", "cancel" — abort with `aborted: by user` without invoking `apply.sh`. Do not pass the cancel string into the script.

## Output Style

- Turn 1: the script's preview block, then one confirmation question.
- Turn 2: at most two lines from the script — `removed:` and optional `detached:`. Or one `aborted:` line on mismatch / cancel.

## Anti-Patterns

- Do not run `apply.sh` in the same turn as `preview.sh`. The double-check must span two user turns; otherwise it is not a double-check.
- Do not accept "yes" / "y" / "확인" / "ok" as confirmation. The script rejects them on purpose — only the exact wiki name confirms.
- Do not fuzzy-match (case-insensitive, trimmed punctuation). The script does not, and neither should you.
- Do not delete a directory that lacks `CLAUDE.md`/`AGENTS.md` — the script refuses; tell the user it is not a wiki.
- Do not skip the attach-state cleanup — the script handles it; do not pre-clear it manually.
- Do not remove multiple wikis per invocation. One name per call.
- Do not re-derive the logic in chat; always invoke the scripts.
