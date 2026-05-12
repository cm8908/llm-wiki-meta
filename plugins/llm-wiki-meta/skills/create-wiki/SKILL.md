---
name: create-wiki
description: Scaffold a new sub-wiki under the user's top-level llm-wiki/ root using the Karpathy LLM Wiki template. Use when the user asks to create a new wiki, add a new category, start a new knowledge base, "위키 만들어", "새 위키", "create wiki", and names the directory. Creates the full template (CLAUDE.md, wiki/, manifests/, tools/wiki_health.py, .claude/skills/{ingest,query,lint}) but does NOT populate domain sources — the user should attach-wiki and ingest afterwards.
---

# create-wiki

## Contract

Create a new sub-wiki directory under the user's `llm-wiki/` root with the local template applied. Scope/content is **not** populated — the wiki ships with empty stubs and placeholders, plus the canonical `karpathy-llm-wiki` source page. After scaffolding, the user is expected to:

1. `attach-wiki <name>` to enter the new wiki.
2. Edit `CLAUDE.md` scope to describe the topic.
3. Use that wiki's `<name>-wiki-ingest` skill to add sources.

This skill creates files. It does not write topic content. It does not perform git operations.

## When To Use

- "create a new wiki named X", "X 위키 만들어줘", "scaffold a new sub-wiki for X".
- The user wants to spin up a new category alongside existing sub-wikis.

## When Not To Use

- The user wants to add a source to an existing wiki → use that wiki's ingest skill.
- The user wants to rename, move, or restructure an existing wiki → manual operation.

## Locate The Root

The ROOT is the top-level `llm-wiki/` directory that holds multiple sub-wikis. Resolve in this order:

1. If the user passed an explicit path, use it.
2. Otherwise start at the current working directory and walk up at most 4 levels. The ROOT is the first ancestor (inclusive) that contains two or more immediate subdirectories each with `CLAUDE.md` or `AGENTS.md`.
3. If detection fails — for example because this is the **first** wiki under a brand-new `llm-wiki/` directory — fall back to the user's current working directory **after asking for confirmation**.
4. Never assume the directory containing this SKILL.md is the ROOT.

Do not scaffold inside an already-attached wiki. Always work at the top-level ROOT.

## Procedure

1. Resolve ROOT (see above).
2. Collect inputs from the user:
   - **Directory name** (required): lowercase, hyphenated, no spaces. Must not already exist under ROOT. Must not collide with reserved auxiliaries (`Excalidraw`, `.obsidian`, `.claude`, `tools`, `manifests`, `wiki`, `raw`).
   - **Topic display name** (optional): used only in the placeholder `CLAUDE.md` title. Defaults to the directory name.
3. Confirm the proposed scaffold list with the user in one short message before writing.
4. Run the scaffold script that ships with this skill. The script sits **next to this SKILL.md** at `${SKILL_DIR}/scaffold.sh`. Determine `${SKILL_DIR}` from the path you just read the SKILL.md from (under a plugin install this will be inside `~/.claude/plugins/...`). Invoke:

   ```bash
   bash "${SKILL_DIR}/scaffold.sh" "$ROOT" "$WIKI_NAME" "$TOPIC_DISPLAY"
   ```

5. Verify the scaffold by running `tools/wiki_health.py` from inside the new wiki. It should print all `[OK]` lines.
6. Respond to the user with:
   - one-line success: `created: <name>`
   - the next-step pointer: `attach-wiki <name>`, edit `CLAUDE.md` scope, then run `<name>-wiki-ingest` on the first source.

## What The Scaffold Writes

- Directory tree: `raw/{papers,web,notes,assets}`, `wiki/{sources,concepts,methods,models,datasets,evaluations,experiments,synthesis,decisions,templates}`, `manifests/`, `tools/`, `.claude/skills/<name>-wiki-{ingest,query,lint}/`.
- `CLAUDE.md` with topic-placeholder scope.
- `wiki/{index,log,current-status}.md` with placeholder content.
- `wiki/templates/{source,concept,decision,synthesis}-page.md`.
- `wiki/sources/karpathy-llm-wiki.md` and `wiki/synthesis/current-thesis.md` stubs.
- `manifests/{raw_sources,datasets,experiments}.csv` with canonical headers; `raw_sources.csv` gets one row for `karpathy-llm-wiki`.
- `tools/wiki_health.py` — the wiki-health linter.
- Three per-wiki skills under `.claude/skills/<name>-wiki-{ingest,query,lint}/` with the wiki name baked into name/description; bodies follow the standard ingest/query/lint contract.

## Output Style

Two short lines after success:

```
created: <name>
next: attach-wiki <name>, edit CLAUDE.md scope, then run <name>-wiki-ingest on your first source.
```

If the linter reported any issues, surface them.

## Anti-Patterns

- Do not populate domain content beyond the `karpathy-llm-wiki` source page. That is ingest's job.
- Do not auto-attach. The user should review the scaffold first.
- Do not pre-fill the topic scope with guessed content. Leave clearly-marked `TODO` placeholders.
- Do not modify any existing wiki. This skill writes only inside the new directory and its new skill subfolders.
- Do not skip the linter. A clean scaffold should pass `tools/wiki_health.py`.
