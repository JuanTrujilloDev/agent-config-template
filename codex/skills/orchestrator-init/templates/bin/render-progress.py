#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyyaml"]
# ///
"""Render PROGRESS.md and PROGRESS-digest.md from state/*.yaml.

The rendered files are generated; edit the YAML (or use state.py) and re-run.
`--check` exits 1 when PROGRESS.md or PROGRESS-digest.md differ from what the
state files would produce.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import (  # noqa: E402
    APPROVER, TRACKER, default_root, list_state_files, load_state, orchestrator_dir, validate_state, lint_runs,
)

GENERATED_BANNER = (
    "<!-- GENERATED from state/*.yaml by bin/render-progress.py. "
    "Do not edit by hand: edit the YAML (or use bin/state.py) and re-run. -->"
)
LAST_RUNS = 10


def _cell(v: Any) -> str:
    if v is None:
        return ""
    s = str(v).replace("|", "\\|").replace("\n", " ").strip()
    return s


def _count(v: Any) -> int:
    return len(v) if isinstance(v, list) else 0


def _bullets(items: Any, empty: str) -> List[str]:
    if isinstance(items, list) and items:
        return [f"- {str(i).strip()}" for i in items]
    return [f"- {empty}"]


def _task_row(d: Dict[str, Any]) -> str:
    cur = d.get("current") or {}
    tracker = d.get("tracker") or {}
    return "| " + " | ".join([
        _cell(d.get("task")),
        _cell(d.get("title")),
        _cell(d.get("project")),
        _cell(d.get("status")),
        _cell(tracker.get("state")),
        _cell(d.get("unchanged_checks", 0)),
        _cell(cur.get("next_step") or "none"),
        str(_count(cur.get("blockers"))),
        str(_count(cur.get("approvals_pending"))),
    ]) + " |"


TABLE_HEADER = [
    f"| Task | Title | Project | Status | {TRACKER} | Unchanged checks | Next step | Blockers | Approvals pending |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
]


def _current_block(d: Dict[str, Any]) -> List[str]:
    cur = d.get("current") or {}
    out: List[str] = []
    summary = (cur.get("summary") or "").strip()
    out.append(summary if summary else "_No summary recorded._")
    out.append("")
    out.append(f"**Next step:** {cur.get('next_step') or 'none'}")
    out.append("")
    out.append("**Blockers:**")
    out += _bullets(cur.get("blockers"), "none")
    out.append("")
    out.append(f"**Approvals pending from {APPROVER}:**")
    out += _bullets(cur.get("approvals_pending"), "none")
    switches = cur.get("model_switches")
    if isinstance(switches, list) and switches:
        out.append("")
        out.append("**Model switches:**")
        out += _bullets(switches, "none")
    return out


def _epics_block(d: Dict[str, Any]) -> List[str]:
    epics = d.get("epics") or []
    if not epics:
        return ["_No epics recorded._"]
    out: List[str] = []
    for epic in epics:
        out.append(f"**Epic {_cell(epic.get('id'))}: {_cell(epic.get('name'))}** — state `{_cell(epic.get('state'))}`")
        out.append("")
        tasks = epic.get("tasks") or []
        if not tasks:
            out.append("_No tasks._")
            out.append("")
            continue
        out.append("| # | Task | Owner | State | Branch / worktree | Thread or task | Notes |")
        out.append("| --- | --- | --- | --- | --- | --- | --- |")
        for t in tasks:
            where = _cell(t.get("branch"))
            if t.get("worktree"):
                where = f"{where} ({_cell(t.get('worktree'))})" if where else _cell(t.get("worktree"))
            out.append("| " + " | ".join([
                _cell(t.get("id")), _cell(t.get("name")), _cell(t.get("owner")), _cell(t.get("state")),
                where, _cell(t.get("thread")), _cell(t.get("notes")),
            ]) + " |")
        out.append("")
    return out


def _runs_block(d: Dict[str, Any]) -> List[str]:
    runs = d.get("runs") or []
    if not runs:
        return ["_No runs recorded._"]
    out = [f"Last {min(LAST_RUNS, len(runs))} of {len(runs)} runs (newest last):", ""]
    out.append("| Run | Kind | Model | State | Result | Report |")
    out.append("| --- | --- | --- | --- | --- | --- |")
    for r in runs[-LAST_RUNS:]:
        report = r.get("report")
        link = f"[{Path(str(report)).name}]({report})" if report else ""
        model = _cell(r.get("model"))
        if r.get("effort"):
            model = f"{model} ({_cell(r.get('effort'))})"
        out.append("| " + " | ".join([
            f"`{_cell(r.get('id'))}`", _cell(r.get("kind")), model, _cell(r.get("state")),
            _cell(r.get("result")), link,
        ]) + " |")
    return out


def render(states: List[Tuple[Path, Dict[str, Any]]]) -> Tuple[str, str]:
    full: List[str] = [GENERATED_BANNER, "", "# Orchestrator progress", ""]
    digest: List[str] = [GENERATED_BANNER, "", "# Orchestrator progress digest", "",
                         "Short view for delegates: the table plus each task's current block. "
                         "Full detail is in `PROGRESS.md` and `state/<task>.yaml`.", ""]

    if not states:
        full += ["_No state files in `state/`._", ""]
        digest += ["_No state files in `state/`._", ""]
        return "\n".join(full), "\n".join(digest)

    table = TABLE_HEADER + [_task_row(d) for _, d in states]
    full += table + [""]
    digest += table + [""]

    for path, d in states:
        head = f"## {_cell(d.get('task'))}: {_cell(d.get('title'))}"
        meta = (
            f"Project `{_cell(d.get('project'))}` · status `{_cell(d.get('status'))}` · {TRACKER} `"
            f"{_cell((d.get('tracker') or {}).get('state'))}` · updated {_cell(d.get('updated'))} · "
            f"plan `{_cell(d.get('plan'))}` · state file `state/{path.name}`"
        )
        current = _current_block(d)

        full += [head, "", meta, "", "### Current", ""] + current + [""]
        full += ["### Epics and tasks", ""] + _epics_block(d) + [""]
        full += ["### Recent runs", ""] + _runs_block(d) + [""]
        full += ["### Sync notes", ""] + _bullets(d.get("sync_notes"), "none") + [""]

        digest += [head, "", meta, ""] + current + [""]

    full += ["## Full run history", ""]
    for path, d in states:
        n = len(d.get("runs") or [])
        full.append(f"- {_cell(d.get('task'))}: {n} runs in `state/{path.name}`")
    full.append("")
    return "\n".join(full), "\n".join(digest)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=default_root(), help="repo root (default: auto-detected)")
    ap.add_argument("--check", action="store_true", help="exit 1 if the rendered files are out of date")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    root = args.root.resolve()
    files = list_state_files(root)
    states: List[Tuple[Path, Dict[str, Any]]] = []
    bad = 0
    for p in files:
        try:
            d = load_state(p)
        except Exception as e:  # noqa: BLE001
            print(f"error: {p}: {e}", file=sys.stderr)
            bad += 1
            continue
        for prob in validate_state(d):
            print(f"warning: {p.name}: {prob}", file=sys.stderr)
        for warn in lint_runs(d):
            print(f"warning: {p.name}: {warn}", file=sys.stderr)
        states.append((p, d))
    states.sort(key=lambda t: str(t[1].get("task")))

    full, digest = render(states)
    odir = orchestrator_dir(root)
    targets = {odir / "PROGRESS.md": full + "\n", odir / "PROGRESS-digest.md": digest + "\n"}

    if args.check:
        stale = []
        for path, text in targets.items():
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                stale.append(path)
        if stale or bad:
            for p in stale:
                print(f"out of date: {p}")
            return 1
        if not args.quiet:
            print("up to date")
        return 0

    odir.mkdir(parents=True, exist_ok=True)
    for path, text in targets.items():
        path.write_text(text, encoding="utf-8")
        if not args.quiet:
            print(f"wrote {path}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
