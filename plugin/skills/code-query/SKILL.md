---
description: Graph-first code querying — consult a codebase knowledge graph (e.g. graphify) before file search when the question is structural (what depends on X, how are A and B connected, what does this subsystem do). Falls back to a deterministic repo map when no graph exists. Reference when planning a spec, decomposing a feature, doing impact analysis, or orienting in an unfamiliar codebase.
---

# Code Query — graph first, grep second

How to answer questions *about* the codebase efficiently. File search (grep /
glob / read) is precise for known symbols but wasteful for structural
questions — you burn context reading raw source to reconstruct relationships a
graph already holds. Query the structure first; read files only once you know
*which* files matter.

## When to use which

| Question shape | Tool |
|---|---|
| "Where is symbol/function/string X?" — known name | `grep` / glob directly. A graph is overkill. |
| "What depends on X?" / "What breaks if I change X?" | Graph (impact analysis), then read the hits. |
| "How are A and B connected?" | Graph path query. |
| "What does this subsystem do?" / unfamiliar repo | Graph communities / repo map, then targeted reads. |
| "Which mini-features does this touch?" (planning) | Graph first — it turns decomposition guesses into listed dependencies. |

## 1. If a knowledge graph is available (e.g. [graphify](https://github.com/Graphify-Labs/graphify))

Detect it: a `graph.json` / `GRAPH_REPORT.md` in the repo, a `graphify` CLI on
PATH, or a graphify MCP server (tools like `query_graph`, `shortest_path`,
`get_node`).

- **Query before file search.** Ask the graph the structural question first:
  - `/graphify query "<question>"` — natural-language question against the graph
  - `/graphify path "<Entity A>" "<Entity B>"` — how two things connect
  - `/graphify explain "<Concept>"` — one node, in context
  - MCP: `query_graph` / `shortest_path` / `get_node` for repeated programmatic access
- **Build or refresh when stale.** `/graphify .` builds the graph for the
  current directory. If the graph predates significant changes (check mtime vs
  recent commits), rebuild before trusting it.
- **Trust labels.** Edges are tagged `EXTRACTED` (explicit in source) or
  `INFERRED` (resolved by reference resolution). Treat `INFERRED` edges as leads
  to verify with a read, not as facts.
- **Then read.** The graph tells you *which* files matter; Read Before You Write
  still applies to every file you edit. The graph never substitutes for reading
  the code you change.

## 2. Fallback — deterministic repo map (no graph installed)

Build a cheap structural view before content-grepping:

1. **Skeleton**: `git ls-files` grouped by directory — the module layout.
2. **Surface**: language-appropriate symbol listing (`ctags`, `grep -n "^(def |class |func |export )"`, or the language server) for the area in question.
3. **Edges**: import/include lines only (`grep -h "^import\|^from\|require("`) to map who-uses-whom for the modules involved.

This costs a few commands, not dozens of full-file reads — and gives the same
"which files matter" answer at lower fidelity.

## Where this plugs into the workflow

- **`/spec` (pmo, CONVERSE/SCOPE)** — query the graph to ground decomposition:
  real dependencies between candidate mini-features, existing code the feature
  can leverage (feeds the **Leverage** subsection of Design notes).
- **`/feature` (implementer)** — impact analysis before editing: what depends
  on the thing you're about to change; check callers via the graph, then read them.
- **`/fix` and debugging** — path queries ("how does the request reach this
  handler?") beat speculative file-hopping.
- **Read Before You Write** (principles) — the graph finds the callers/usages
  you owe a check; the reading itself is never skipped.
