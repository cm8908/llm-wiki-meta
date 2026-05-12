#!/usr/bin/env bash
# scaffold.sh ROOT WIKI_NAME [TOPIC_DISPLAY]
#
# Scaffolds a new sub-wiki under ROOT/WIKI_NAME with the local llm-wiki template.
# Does NOT populate domain content. The user should attach-wiki then ingest.

set -euo pipefail

ROOT="${1:?usage: scaffold.sh ROOT WIKI_NAME [TOPIC_DISPLAY]}"
WIKI="${2:?usage: scaffold.sh ROOT WIKI_NAME [TOPIC_DISPLAY]}"
TOPIC="${3:-$WIKI}"

# ---- validate name ----
case "$WIKI" in
  .*|*/*|*\ *|*\\*)
    echo "error: invalid wiki name '$WIKI'" >&2; exit 2 ;;
esac
if ! [[ "$WIKI" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "error: name must be lowercase, digits, and hyphens only" >&2; exit 2
fi
case "$WIKI" in
  Excalidraw|.obsidian|.claude|tools|manifests|wiki|raw)
    echo "error: '$WIKI' is reserved" >&2; exit 2 ;;
esac
DEST="$ROOT/$WIKI"
if [ -e "$DEST" ]; then
  echo "error: '$DEST' already exists" >&2; exit 2
fi

# ---- create directory tree ----
mkdir -p \
  "$DEST/raw/papers" \
  "$DEST/raw/web" \
  "$DEST/raw/notes" \
  "$DEST/raw/assets" \
  "$DEST/wiki/sources" \
  "$DEST/wiki/concepts" \
  "$DEST/wiki/methods" \
  "$DEST/wiki/models" \
  "$DEST/wiki/datasets" \
  "$DEST/wiki/evaluations" \
  "$DEST/wiki/experiments" \
  "$DEST/wiki/synthesis" \
  "$DEST/wiki/decisions" \
  "$DEST/wiki/templates" \
  "$DEST/manifests" \
  "$DEST/tools" \
  "$DEST/.claude/skills/${WIKI}-wiki-ingest" \
  "$DEST/.claude/skills/${WIKI}-wiki-query" \
  "$DEST/.claude/skills/${WIKI}-wiki-lint"

today="$(date '+%Y-%m-%d')"

# ---- CLAUDE.md ----
cat > "$DEST/CLAUDE.md" <<EOF
# ${TOPIC} Wiki Agent Contract

This repository is an LLM-maintained wiki for **${TOPIC}**. The wiki follows the "LLM Wiki" pattern (see [[sources/karpathy-llm-wiki]]): raw sources are preserved as source truth, while the agent maintains a structured markdown knowledge layer that compounds over time.

## Scope

TODO: replace this placeholder with the in-scope / adjacent / out-of-scope description for ${TOPIC}.

In scope:

- TODO.

Adjacent but secondary, ingest only when directly load-bearing:

- TODO.

Out of scope unless the user explicitly opts in:

- TODO.

## Layers

- \`raw/\` contains curated source artifacts (papers, blog posts, model cards, notes, assets). Treat this layer as immutable unless the user explicitly asks to add a new artifact.
- \`wiki/\` contains agent-maintained markdown pages. The agent creates, updates, links, and repairs this layer.
- \`manifests/\` contains CSV ledgers for sources, datasets, and experiments.
- \`.claude/skills/\` contains project-local Claude Code skills for wiki operations.
- \`tools/\` contains deterministic helper scripts used by skills.

## Skill Dispatch

- Use \`.claude/skills/${WIKI}-wiki-ingest/SKILL.md\` when the user asks to ingest, add, process, summarize, compile, or incorporate a source.
- Use \`.claude/skills/${WIKI}-wiki-query/SKILL.md\` when the user asks a question against the wiki, asks for a summary, comparison, report, synthesis, or explanation.
- Use \`.claude/skills/${WIKI}-wiki-lint/SKILL.md\` when the user asks to lint, audit, validate, repair, clean up, or health-check the wiki.

## Invariants

- Do not edit or delete existing files under \`raw/\` unless the user explicitly asks for raw-source changes.
- Keep durable conclusions in \`wiki/synthesis/\` or \`wiki/decisions/\`, not only in chat.
- Every important factual claim should trace to a source page under \`wiki/sources/\` or to a raw artifact recorded in \`manifests/raw_sources.csv\`.
- Use stable lowercase hyphenated ids.
- Use ISO dates. The local project timezone is Asia/Seoul.
- Prefer Obsidian links such as \`[[sources/source-id]]\` and \`[[synthesis/current-thesis]]\`.
- Preserve disagreement. Do not smooth contradictions between sources into a false consensus.
- For current model availability, leaderboards, licenses, pricing, APIs, or hosted product claims, verify against current primary sources before recording facts.

## Wiki Page Types

- \`wiki/sources/\`: canonical source summaries for papers, posts, model cards, repos, datasets, reports, and notes.
- \`wiki/concepts/\`: reusable ideas in this domain.
- \`wiki/methods/\`: algorithms, recipes, and procedures.
- \`wiki/models/\`: model or system pages where the model is the object of study.
- \`wiki/datasets/\`: dataset pages with provenance, splits, licenses, and leakage risks.
- \`wiki/evaluations/\`: benchmark and evaluation pages with metrics, baselines, and comparability limits.
- \`wiki/experiments/\`: local experiment plans, runs, observations, and artifacts.
- \`wiki/synthesis/\`: cross-source analysis, open questions, current thesis, and reusable comparisons.
- \`wiki/decisions/\`: project decisions, tradeoffs, and accepted conventions.

## Source Page Minimum

A source page should include:

- Source metadata: id, title, authors or organization, date, URL or raw path, access date, type, status, language, and license when known.
- Core claims and evidence.
- Relevance to ${TOPIC}.
- Methods, datasets, models, or evaluations touched by the source.
- Limitations, caveats, contradictions, and open questions.
- Links to affected wiki pages.

## Manifest Schemas

\`manifests/raw_sources.csv\` columns:

\`source_id,title,authors_or_org,source_type,source_url,raw_path,date_published,date_accessed,status,license,language,domain_tags,notes\`

\`manifests/datasets.csv\` columns:

\`dataset_id,title,source_id,task,language,license,status,split_notes,leakage_risks,notes\`

\`manifests/experiments.csv\` columns:

\`experiment_id,title,date_run,status,code_path,artifact_path,source_ids,metrics,notes\`
EOF

# ---- wiki/index.md ----
cat > "$DEST/wiki/index.md" <<EOF
# ${TOPIC} Wiki Index

This index is the content map for the maintained wiki. Read it first when querying the knowledge base, and update it after every ingest or durable synthesis.

## Core

- [[current-status]] - Current scope, operating assumptions, and next useful sources.
- [[log]] - Chronological record of ingests, queries, lint passes, and structural changes.
- [[synthesis/current-thesis]] - Starting synthesis for the ${TOPIC} knowledge base.

## Sources

- [[sources/karpathy-llm-wiki]] - Karpathy's LLM Wiki pattern used as the architecture source for this repository.

## Concepts

<!-- TODO: list concept pages -->

## Methods

<!-- TODO: list method pages -->

## Models

<!-- TODO: list model pages -->

## Datasets

<!-- TODO: list dataset pages -->

## Evaluations

<!-- TODO: list evaluation pages -->

## Experiments

<!-- TODO: list experiment pages -->

## Synthesis

- [[synthesis/current-thesis]] - Working thesis for ${TOPIC}.

## Decisions

<!-- TODO: list decision pages -->
EOF

# ---- wiki/log.md ----
cat > "$DEST/wiki/log.md" <<EOF
# Log

## [${today}] init | ${TOPIC} wiki scaffold

- Created the project-local LLM Wiki structure: \`raw/\`, \`wiki/\`, \`manifests/\`, \`.claude/skills/\`, and \`tools/\`.
- Added project-local skills for ingest, query, and lint workflows.
- Registered [[sources/karpathy-llm-wiki]] as the architecture source for this repository.
EOF

# ---- wiki/current-status.md ----
cat > "$DEST/wiki/current-status.md" <<EOF
# Current Status

## Scope

TODO: describe what this wiki tracks. Replace this placeholder when the topic scope is finalized.

## Starting Point

The repository contains the wiki scaffold and the architecture source [[sources/karpathy-llm-wiki]]. No domain sources have been ingested yet.

## Operating Assumptions

- Start with curated sources one at a time.
- Keep raw artifacts immutable.
- Prefer compact source pages plus cross-linked concept, method, dataset, evaluation, and synthesis pages.
- Treat fast-moving claims about model releases, hosted APIs, leaderboards, and licenses as time-sensitive.

## Next Useful Sources

- TODO: list the first sources to ingest.
EOF

# ---- wiki/synthesis/current-thesis.md ----
cat > "$DEST/wiki/synthesis/current-thesis.md" <<EOF
# Current Thesis

## Question

What is the source-grounded working answer for ${TOPIC} right now?

## Synthesis

TODO. No domain sources ingested yet. Replace this placeholder once at least one source has been added to \`wiki/sources/\`.

## Evidence

- [[sources/karpathy-llm-wiki]] - Architectural pattern only; not domain evidence.

## Disagreements Or Caveats

- TODO.

## Next Sources

- TODO.
EOF

# ---- wiki/sources/karpathy-llm-wiki.md ----
cat > "$DEST/wiki/sources/karpathy-llm-wiki.md" <<EOF
# Karpathy LLM Wiki

## Metadata

- source_id: \`karpathy-llm-wiki\`
- title: \`LLM Wiki\`
- authors_or_org: Andrej Karpathy
- source_type: gist
- source_url: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- raw_path: unknown
- date_published: 2026-04-04
- date_accessed: ${today}
- status: ingested
- language: en
- license: not specified

## Core Claims

- An "LLM Wiki" is a long-lived, agent-maintained markdown knowledge base in which raw sources are preserved as source truth and the agent compounds a structured wiki layer over time.
- The wiki separates immutable raw artifacts from a curated, cross-linked wiki layer; the agent's job is to keep that layer trustworthy.
- Manifests (CSV ledgers) sit beside the wiki to track sources, datasets, and experiments in a machine-readable form.

## Evidence And Methods

- Pattern is the architectural source for this repository's directory layout (\`raw/\`, \`wiki/\`, \`manifests/\`, \`.claude/skills/\`, \`tools/\`).

## Relevance

- This source is the architecture source for the repository itself. It does not contribute domain evidence; it constrains how this wiki is structured and operated.

## Affected Pages

- [[current-status]]
- [[synthesis/current-thesis]]

## Limitations And Open Questions

- The pattern is opinionated and assumes an agent in the loop; readers without an agent may need to adapt the workflow.
EOF

# ---- wiki/templates/*.md ----
cat > "$DEST/wiki/templates/source-page.md" <<'EOF'
# Source Title

## Metadata

- source_id: `stable-source-id`
- title: `Source Title`
- authors_or_org: unknown
- source_type: paper | report | blog | model-card | dataset | code | note | experiment | other
- source_url: unknown
- raw_path: unknown
- date_published: unknown
- date_accessed: YYYY-MM-DD
- status: draft | ingested | superseded
- language: unknown
- license: unknown

## Core Claims

- Claim with provenance-preserving caveats.

## Evidence And Methods

- Methods, data, metrics, baselines, or experimental setup.

## Relevance

- Why this source matters for the wiki topic.

## Affected Pages

- [[synthesis/current-thesis]]

## Limitations And Open Questions

- Unknowns, contradictions, or risks.
EOF

cat > "$DEST/wiki/templates/concept-page.md" <<'EOF'
# Concept Name

## Definition

Brief source-grounded definition.

## Why It Matters

How the concept affects the topic's methods, datasets, evaluations, or risks.

## Evidence

- [[sources/source-id]] - relevant claim or caveat.

## Related Pages

- [[synthesis/current-thesis]]

## Open Questions

- Unresolved question.
EOF

cat > "$DEST/wiki/templates/decision-page.md" <<'EOF'
# Decision Title

## Status

proposed | accepted | superseded

## Decision

State the project choice.

## Rationale

Why this choice is useful for the wiki or research workflow.

## Evidence

- [[sources/source-id]] - supporting source.

## Consequences

- Expected benefits, tradeoffs, and follow-up work.
EOF

cat > "$DEST/wiki/templates/synthesis-page.md" <<'EOF'
# Synthesis Title

## Question

What reusable cross-source question does this page answer?

## Synthesis

Summarize the current source-grounded answer. Mark inference explicitly.

## Evidence

- [[sources/source-id]] - claim used.

## Disagreements Or Caveats

- Source-level disagreement, missing evidence, or non-comparable results.

## Next Sources

- Specific source gaps to fill.
EOF

# ---- manifests/*.csv ----
cat > "$DEST/manifests/raw_sources.csv" <<EOF
source_id,title,authors_or_org,source_type,source_url,raw_path,date_published,date_accessed,status,license,language,domain_tags,notes
karpathy-llm-wiki,LLM Wiki,Andrej Karpathy,gist,https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f,,2026-04-04,${today},ingested,not specified,en,knowledge-base;workflow,Architecture source for this repository
EOF

cat > "$DEST/manifests/datasets.csv" <<'EOF'
dataset_id,title,source_id,task,language,license,status,split_notes,leakage_risks,notes
EOF

cat > "$DEST/manifests/experiments.csv" <<'EOF'
experiment_id,title,date_run,status,code_path,artifact_path,source_ids,metrics,notes
EOF

echo "scaffold base done at $DEST"

# ---- tools/wiki_health.py ----
cat > "$DEST/tools/wiki_health.py" <<'PYEOF'
#!/usr/bin/env python3
"""Basic health checks for the local LLM wiki."""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path


WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")


def rel(path: Path, root: Path) -> str:
    return str(path.relative_to(root)).replace("\\", "/")


def markdown_pages(wiki_dir: Path) -> list[Path]:
    return sorted(p for p in wiki_dir.rglob("*.md") if p.is_file())


def page_key(page: Path, wiki_dir: Path) -> str:
    return rel(page, wiki_dir)[:-3]


def resolve_link(raw_target: str, page: Path, wiki_dir: Path, pages: list[Path]) -> list[Path]:
    target = raw_target.split("|", 1)[0].split("#", 1)[0].strip()
    if not target:
        return []

    target_path = Path(target)
    if target_path.suffix != ".md":
        target_path = target_path.with_suffix(".md")

    candidates = [
        (wiki_dir / target_path).resolve(),
        (page.parent / target_path).resolve(),
    ]

    resolved_pages = {p.resolve(): p for p in pages}
    hits = [resolved_pages[c] for c in candidates if c in resolved_pages]

    if "/" not in target:
        stem_hits = [p for p in pages if p.stem == target]
        key_hits = [p for p in pages if page_key(p, wiki_dir) == target]
        for hit in stem_hits + key_hits:
            if hit not in hits:
                hits.append(hit)

    return hits


def check_structure(root: Path) -> list[str]:
    issues: list[str] = []
    for required in ["CLAUDE.md", "wiki", "manifests", ".claude/skills"]:
        if not (root / required).exists():
            issues.append(f"missing required path: {required}")
    return issues


def check_wikilinks(root: Path) -> list[str]:
    wiki_dir = root / "wiki"
    if not wiki_dir.exists():
        return ["missing wiki directory"]

    issues: list[str] = []
    pages = markdown_pages(wiki_dir)
    for page in pages:
        if page_key(page, wiki_dir).startswith("templates/"):
            continue
        text = page.read_text(encoding="utf-8")
        for match in WIKILINK_RE.finditer(text):
            hits = resolve_link(match.group(1), page, wiki_dir, pages)
            if not hits:
                issues.append(f"broken wikilink in {rel(page, root)}: [[{match.group(1)}]]")
            elif len({h.resolve() for h in hits}) > 1:
                issues.append(f"ambiguous wikilink in {rel(page, root)}: [[{match.group(1)}]]")
    return issues


def check_index_coverage(root: Path) -> list[str]:
    wiki_dir = root / "wiki"
    index = wiki_dir / "index.md"
    if not index.exists():
        return ["missing wiki/index.md"]

    index_text = index.read_text(encoding="utf-8")
    issues: list[str] = []
    excluded = {
        "index",
        "log",
    }
    for page in markdown_pages(wiki_dir):
        key = page_key(page, wiki_dir)
        if key in excluded or key.startswith("templates/"):
            continue
        if key not in index_text and f"[[{key}]]" not in index_text and page.stem not in index_text:
            issues.append(f"page missing from index: wiki/{key}.md")
    return issues


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]], list[str]]:
    if not path.exists():
        return [], [], [f"missing manifest: {rel(path, path.parent.parent)}"]
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        headers = reader.fieldnames or []
    return headers, rows, []


def check_manifests(root: Path) -> list[str]:
    issues: list[str] = []
    manifests = root / "manifests"
    raw_headers, raw_rows, raw_errors = read_csv(manifests / "raw_sources.csv")
    issues.extend(raw_errors)

    expected_raw = [
        "source_id",
        "title",
        "authors_or_org",
        "source_type",
        "source_url",
        "raw_path",
        "date_published",
        "date_accessed",
        "status",
        "license",
        "language",
        "domain_tags",
        "notes",
    ]
    if raw_headers and raw_headers != expected_raw:
        issues.append("raw_sources.csv header does not match CLAUDE.md schema")

    seen_ids: set[str] = set()
    for row in raw_rows:
        source_id = (row.get("source_id") or "").strip()
        status = (row.get("status") or "").strip()
        if not source_id:
            issues.append("raw_sources.csv row missing source_id")
            continue
        if source_id in seen_ids:
            issues.append(f"duplicate source_id in raw_sources.csv: {source_id}")
        seen_ids.add(source_id)
        if status == "ingested" and not (root / "wiki" / "sources" / f"{source_id}.md").exists():
            issues.append(f"ingested source missing wiki page: {source_id}")

    for name in ["datasets.csv", "experiments.csv"]:
        headers, _rows, errors = read_csv(manifests / name)
        issues.extend(errors)
        if headers and any(not h for h in headers):
            issues.append(f"{name} has an empty header column")

    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="Run basic LLM wiki health checks.")
    parser.add_argument("root", nargs="?", default=".", help="Wiki repository root")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    checks = [
        ("structure", check_structure(root)),
        ("wikilinks", check_wikilinks(root)),
        ("index", check_index_coverage(root)),
        ("manifests", check_manifests(root)),
    ]

    issue_count = 0
    for name, issues in checks:
        if issues:
            issue_count += len(issues)
            print(f"[FAIL] {name}")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print(f"[OK] {name}")

    if issue_count:
        print(f"\n{issue_count} issue(s) found.")
        return 1

    print("\nNo wiki health issues found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
PYEOF
chmod +x "$DEST/tools/wiki_health.py"

# ---- .claude/skills/<wiki>-wiki-ingest/SKILL.md ----
cat > "$DEST/.claude/skills/${WIKI}-wiki-ingest/SKILL.md" <<EOF
---
name: ${WIKI}-wiki-ingest
description: Ingest new source material into the project-local ${WIKI} markdown wiki. Use when Claude is asked to add, process, compile, summarize, or integrate papers, reports, web pages, model cards, datasets, code repositories, notes, or experiment outputs into this repository's \`raw/\`, \`wiki/\`, and \`manifests/\` layers.
---

# ${TOPIC} Wiki Ingest

## Contract

Compile new evidence into the maintained wiki instead of only answering in chat. Preserve \`raw/\` as source truth. Create or update wiki pages, manifests, index entries, and the log so the knowledge base compounds.

## Locate The Wiki

Work from the repository root. Prefer the current directory if it contains \`CLAUDE.md\`, \`wiki/\`, \`manifests/\`, and \`.claude/skills/\`. Otherwise search downward from the current directory for that shape.

Read these first:

- \`CLAUDE.md\`
- \`wiki/index.md\`
- \`wiki/log.md\`
- \`wiki/current-status.md\`
- relevant manifest headers under \`manifests/\`

## Ingest Workflow

1. Identify metadata: canonical title, authors or organization, publication date, source URL or raw path, source type, license, language, and access date.
2. Read the source deeply enough to extract claims, evidence, methods, metrics, datasets, caveats, and relevance to ${TOPIC}.
3. For remote or time-sensitive sources (model cards, leaderboards, hosted-API docs), verify against current primary sources before recording facts.
4. Choose a stable lowercase hyphenated \`source_id\`. Reuse an existing id if the source is already represented.
5. Preserve raw source truth:
   - If the source already exists under \`raw/\`, do not edit it.
   - If the user provides a URL only, record the URL in the manifest.
   - If the user explicitly asks to store a raw artifact, place it under the relevant \`raw/\` subdirectory and record the path.
6. Create or update \`wiki/sources/<source_id>.md\` using \`wiki/templates/source-page.md\` as the baseline style.
7. Update affected pages under \`wiki/concepts/\`, \`wiki/methods/\`, \`wiki/models/\`, \`wiki/datasets/\`, \`wiki/evaluations/\`, \`wiki/experiments/\`, \`wiki/synthesis/\`, or \`wiki/decisions/\`.
8. Update \`wiki/index.md\` so new and changed pages are discoverable.
9. Update manifests:
   - \`manifests/raw_sources.csv\` for every source.
   - \`manifests/datasets.csv\` for reusable datasets or benchmark datasets.
   - \`manifests/experiments.csv\` for local experiment runs or reproducibility attempts.
10. Append a short entry to \`wiki/log.md\` under the current local date (Asia/Seoul).

## Writing Rules

- Keep source summaries compact but specific enough that future queries do not need to reread the raw source for basic facts.
- Preserve dates, caveats, exact scope, and non-comparability.
- Link every cross-source conclusion to source pages.
- Label inference as synthesis.
- Flag contradictions or superseded claims instead of silently merging them.
- Distinguish author-reported numbers from independently reproduced numbers.
- Prefer Obsidian links such as \`[[sources/source-id]]\`.

## Completion Checklist

- The source has exactly one canonical source page.
- Index and manifest entries use the same id, title, status, and source path or URL.
- Important affected concept, method, model, dataset, evaluation, experiment, synthesis, or decision pages were updated.
- New claims have provenance.
- \`raw/\` was not modified unless explicitly requested.
- \`wiki/log.md\` records the ingest.
EOF

# ---- .claude/skills/<wiki>-wiki-query/SKILL.md ----
cat > "$DEST/.claude/skills/${WIKI}-wiki-query/SKILL.md" <<EOF
---
name: ${WIKI}-wiki-query
description: Answer questions from the project-local ${WIKI} markdown wiki. Use when Claude is asked to search, summarize, compare, explain, report, synthesize, or make a recommendation using this repository's wiki pages, source pages, manifests, and optional raw artifacts.
---

# ${TOPIC} Wiki Query

## Contract

Use the maintained wiki as the first knowledge layer. Search raw sources only when the wiki lacks needed evidence, exact wording, or provenance. Do not modify \`raw/\`. Write back to the wiki only when the user asks for a durable artifact or the answer creates reusable synthesis worth preserving.

## Locate The Wiki

Work from the repository root. Prefer the current directory if it contains \`CLAUDE.md\`, \`wiki/\`, \`manifests/\`, and \`.claude/skills/\`. Otherwise search downward from the current directory for that shape.

Read these first unless the question is obviously narrow:

- \`CLAUDE.md\`
- \`wiki/index.md\`
- \`wiki/current-status.md\`
- \`wiki/synthesis/current-thesis.md\`
- \`wiki/log.md\` when recency or recent changes matter

## Query Workflow

1. Translate the user question into needed evidence: sources, concepts, methods, models, datasets, evaluations, experiments, or decisions.
2. Search \`wiki/\` with \`rg\` using acronyms, aliases, Korean and English variants, likely page names, source ids, and known model or benchmark names.
3. Read the index and the most relevant pages. Follow links to source pages when a claim needs provenance.
4. If the wiki lacks enough evidence, say so clearly. Use raw sources or web verification only when needed and distinguish that from wiki evidence.
5. Synthesize across pages. Identify agreement, disagreement, evaluation non-comparability, and open questions.

## Writing Rules

- Cite source pages with Obsidian links such as \`[[sources/source-id]]\`.
- Label inference as synthesis and keep it separate from cited claims.
- Preserve dates and exact scope.
- When the question implies a durable conclusion (recommendation, decision, thesis update), offer to record it in \`wiki/synthesis/\` or \`wiki/decisions/\`.

## Completion Checklist

- Claims are grounded in wiki pages, or marked as inference or external.
- The answer lists which wiki pages were consulted.
- If the wiki was insufficient, the gap is named explicitly.
EOF

# ---- .claude/skills/<wiki>-wiki-lint/SKILL.md ----
cat > "$DEST/.claude/skills/${WIKI}-wiki-lint/SKILL.md" <<EOF
---
name: ${WIKI}-wiki-lint
description: Audit and repair the project-local ${WIKI} markdown wiki. Use when Claude is asked to lint, validate, health-check, audit, clean up, or repair wiki structure, Obsidian links, index coverage, manifests, source provenance, stale claims, contradictions, orphan pages, or research risks.
---

# ${TOPIC} Wiki Lint

## Contract

Keep the wiki trustworthy as a persistent knowledge layer. Prefer narrow repairs over broad rewrites. Preserve \`raw/\` unless the user explicitly asks for raw-source changes.

## Locate The Wiki

Work from the repository root. Prefer the current directory if it contains \`CLAUDE.md\`, \`wiki/\`, \`manifests/\`, and \`.claude/skills/\`. Otherwise search downward from the current directory for that shape.

Read these first:

- \`CLAUDE.md\`
- \`wiki/index.md\`
- \`wiki/log.md\`
- \`wiki/current-status.md\`
- manifest headers under \`manifests/\`

## Fast Mechanical Check

If \`tools/wiki_health.py\` exists, run:

\`\`\`bash
python3 tools/wiki_health.py .
\`\`\`

The script checks structure, wikilinks, index coverage, and manifest header consistency. Treat its output as the starting point.

## Lint Categories

- Structure: required files and directories exist.
- Links: every \`[[wikilink]]\` resolves to exactly one page.
- Index coverage: every page (except \`templates/\`, \`index\`, \`log\`) is reachable from \`wiki/index.md\`.
- Manifests: headers match \`CLAUDE.md\` schema; \`source_id\` is unique; every \`ingested\` source has a corresponding \`wiki/sources/<id>.md\`.
- Source provenance: every important claim points back to a source page or raw artifact.
- Stale or contradicted claims: surface, don't silently merge.

## Repair Rules

- Prefer the smallest correct change.
- Do not invent sources or citations to satisfy the linter.
- If a fact cannot be verified, mark it as needing follow-up rather than deleting it.
- Record meaningful repairs in \`wiki/log.md\`.

## Completion Checklist

- \`tools/wiki_health.py\` runs clean, or every remaining issue is explained.
- No new contradictions introduced.
- \`wiki/log.md\` records the lint pass when changes were made.
EOF

echo "scaffold done at $DEST"
