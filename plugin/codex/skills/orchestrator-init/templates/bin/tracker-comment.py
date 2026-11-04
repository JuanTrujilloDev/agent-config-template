#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyyaml"]
# ///
"""Render the tracker comment for one task from its state file.

This script never calls the tracker. It only renders the text, so the comment
always matches the state file. Post it through the connection AGENTS.md names,
only after the approver's yes, then record the comment id with:

  state.py --task ABC-123 set tracker.last_comment_id=<id> --no-render

Output: Markdown by default, `--html` for comment_html.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any, Dict, List

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import APPROVER, default_root, load_state, state_path  # noqa: E402


def _esc(s: Any) -> str:
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def render(d: Dict[str, Any], html: bool) -> str:
    cur = d.get("current") or {}
    runs = (d.get("runs") or [])[-3:]
    blockers = cur.get("blockers") or ["none"]
    approvals = cur.get("approvals_pending") or ["none"]
    if html:
        out: List[str] = [
            f"<p><strong>{_esc(d.get('task'))} orchestrator sync</strong> ({_esc(d.get('updated'))}) "
            f"— status <code>{_esc(d.get('status'))}</code></p>",
            f"<p>{_esc((cur.get('summary') or '').strip())}</p>",
            f"<p><strong>Next step:</strong> {_esc(cur.get('next_step') or 'none')}</p>",
            "<p><strong>Blockers:</strong></p><ul>" + "".join(f"<li>{_esc(b)}</li>" for b in blockers) + "</ul>",
            f"<p><strong>Approvals pending from {_esc(APPROVER)}:</strong></p><ul>"
            + "".join(f"<li>{_esc(a)}</li>" for a in approvals) + "</ul>",
        ]
        if runs:
            out.append("<p><strong>Last runs:</strong></p><ul>" + "".join(
                f"<li><code>{_esc(r.get('id'))}</code> {_esc(r.get('kind'))} {_esc(r.get('model') or '')} — "
                f"{_esc(r.get('state'))}{' / ' + _esc(r.get('result')) if r.get('result') else ''}"
                f"{' — ' + _esc(r.get('report')) if r.get('report') else ''}</li>" for r in runs) + "</ul>")
        return "".join(out)
    out = [
        f"**{d.get('task')} orchestrator sync** ({d.get('updated')}) — status `{d.get('status')}`",
        "",
        (cur.get("summary") or "").strip(),
        "",
        f"**Next step:** {cur.get('next_step') or 'none'}",
        "",
        "**Blockers:**",
        *[f"- {b}" for b in blockers],
        "",
        f"**Approvals pending from {APPROVER}:**",
        *[f"- {a}" for a in approvals],
    ]
    if runs:
        out += ["", "**Last runs:**"] + [
            f"- `{r.get('id')}` {r.get('kind')} {r.get('model') or ''} — {r.get('state')}"
            f"{' / ' + str(r.get('result')) if r.get('result') else ''}"
            f"{' — ' + str(r.get('report')) if r.get('report') else ''}" for r in runs]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=None, help="repo root (default: auto)")
    ap.add_argument("--task", required=True, help="tracker task ID, e.g. ABC-123")
    ap.add_argument("--html", action="store_true", help="emit comment_html instead of Markdown")
    a = ap.parse_args()
    root = a.root or default_root()
    d = load_state(state_path(root, a.task))
    sys.stdout.write(render(d, a.html))
    return 0


if __name__ == "__main__":
    sys.exit(main())
