# llm-wiki-meta

A Claude Code / Cowork plugin that adds **meta-level skills** for managing a multi-category LLM wiki in the [Andrej Karpathy "LLM Wiki" pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

If you keep multiple `CLAUDE.md`-anchored wikis (e.g. `generative-embeddings/`, `llm-rl/`, `legal-embedding-eval/`) under a single top-level `llm-wiki/` directory, this plugin lets Claude:

- **`list-wikis`** — enumerate sub-wikis with their layers (`wiki/manifests/raw/tools`) and the currently attached one.
- **`current-wiki`** — one-line report of which sub-wiki is currently attached (or `(none)`).
- **`attach-wiki <name>`** — pin the current session to a single sub-wiki so subsequent work runs inside that context. Persists to `<ROOT>/.claude/state/attached-wiki`.
- **`detach-wiki`** — clear the attached state and return to the top-level meta scope.
- **`create-wiki <name>`** — scaffold a new sub-wiki with the full template: `CLAUDE.md`, `wiki/{sources,concepts,methods,models,datasets,evaluations,experiments,synthesis,decisions,templates}`, `manifests/{raw_sources,datasets,experiments}.csv`, `tools/wiki_health.py`, and three per-wiki skills (`<name>-wiki-ingest|query|lint`). The wiki ships lint-clean and pre-registers `karpathy-llm-wiki` as the architecture source.
- **`remove-wiki <name>`** — permanently delete a sub-wiki after a double-check (the user must re-type the exact wiki name). Also clears the attach state if the deleted wiki was the attached one.
- **`wiki-ingest` / `wiki-query` / `wiki-lint`** — meta-level entry points that dispatch to the currently attached wiki's local `<name>-wiki-ingest|query|lint` skill. **They refuse if no wiki is attached** — the meta scope is never a valid target.

## Install

This repository is its own marketplace. From Claude Code or Cowork:

```text
/plugin marketplace add cm8908/llm-wiki-meta
/plugin install llm-wiki-meta@cm8908-llm-wiki
```

(or pass the full URL: `https://github.com/cm8908/llm-wiki-meta`)

After install, all four skills appear in the slash-menu.

## Expected Layout

The skills assume a directory like:

```
llm-wiki/                       # the ROOT
├── generative-embeddings/      # sub-wiki (has CLAUDE.md)
├── legal-embedding-eval/       # sub-wiki (has AGENTS.md)
├── llm-rl/                     # sub-wiki (has CLAUDE.md)
├── Excalidraw/                 # ignored — no CLAUDE.md/AGENTS.md
├── .obsidian/                  # ignored — hidden
└── .claude/state/              # created on first attach
    └── attached-wiki           # one-line wiki name
```

Each sub-wiki is detected by the presence of a `CLAUDE.md` **or** `AGENTS.md` file in its top directory.

## Root Detection

Skills auto-detect the ROOT by walking up from the current working directory until they find an ancestor containing two or more sibling subdirectories that each have `CLAUDE.md` or `AGENTS.md`. You can also pass the root explicitly. See each `SKILL.md` for the contract.

When using **`create-wiki` for the very first wiki in a brand-new `llm-wiki/`**, the heuristic cannot trigger — Claude will fall back to the current working directory after asking you to confirm.

## Skills Provided

| Skill | What it does |
| --- | --- |
| `list-wikis` | Read-only listing of sub-wikis. |
| `current-wiki` | Print which sub-wiki is currently attached (or `(none)`). |
| `attach-wiki <name>` | Pin the session to a sub-wiki; warn on cross-wiki access. |
| `detach-wiki` | Clear the attach state. |
| `create-wiki <name> [topic]` | Scaffold a new sub-wiki from the Karpathy template. |
| `remove-wiki <name>` | Permanently delete a sub-wiki after the user re-types the name. |
| `wiki-ingest` | Dispatch to the attached wiki's `<name>-wiki-ingest`. Refuses if none attached. |
| `wiki-query` | Dispatch to the attached wiki's `<name>-wiki-query`. Refuses if none attached. |
| `wiki-lint` | Dispatch to the attached wiki's `<name>-wiki-lint`. Refuses if none attached. |

## License

MIT. See `LICENSE`.
