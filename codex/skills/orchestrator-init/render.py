#!/usr/bin/env python3
"""Render the orchestrator skeleton from templates/ into --target.

Without --write: print the plan (create / skip / conflict per file) and write nothing.
A conflict (a file where a folder is needed) exits 2 before anything is written.
With --write: create the missing files, never overwrite an existing one, then
print the two schedule prompts for the user to create by hand in T3.
Standard library only. Run it with `python3 -I`.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent / "templates"
SCHEDULES = ("schedules/progress-check.md", "schedules/config-review.md")
# Names land inside a Python string literal in bin/_common.py, so quotes and backslashes are out.
SAFE_NAME = re.compile(r"[\w][\w .'-]{0,59}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--target", required=True, type=Path, help="orchestrator folder to create or fill")
    ap.add_argument("--tracker", required=True, help="project tracker name, e.g. Plane, Jira, Linear")
    ap.add_argument("--approver", required=True, help="the person who approves plans, launches and pushes")
    ap.add_argument("--write", action="store_true", help="write the missing files (default: plan only)")
    args = ap.parse_args()

    for flag, value in (("--tracker", args.tracker), ("--approver", args.approver)):
        if not SAFE_NAME.fullmatch(value):
            print(f"error: {flag} must be letters, digits, spaces, . ' - _ (max 60), got {value!r}", file=sys.stderr)
            return 2
    target = args.target.expanduser().resolve()
    tokens = {"{{approver}}": args.approver, "{{tracker}}": args.tracker, "{{orchestrator_dir}}": str(target)}

    print(f"Orchestrator folder: {target}")
    # Plan every file first, so a conflict stops the run before anything is written.
    plan, conflict = [], False
    for src in sorted(p for p in TEMPLATES.rglob("*") if p.is_file()):
        rel = src.relative_to(TEMPLATES)
        dst = target / rel
        # Every folder the file needs, from / down to its parent: an existing non-folder blocks mkdir.
        blocker = next((a for a in reversed(dst.parents) if (a.exists() or a.is_symlink()) and not a.is_dir()), None)
        if blocker:
            print(f"conflict {rel} ({blocker} exists and is not a folder)")
            conflict = True
        elif dst.exists() or dst.is_symlink():
            print(f"skip    {rel} (exists, left as is)")
        else:
            print(f"create  {rel}")
            plan.append((src, dst))

    if conflict:
        print("\nConflict: move or rename the paths above, then re-run. Nothing written.")
        return 2
    if not args.write:
        print("\nPlan only: nothing written. Re-run with --write after the user says yes.")
        return 0
    for src, dst in plan:
        text = src.read_text(encoding="utf-8")
        for token, value in tokens.items():
            text = text.replace(token, value)
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(text, encoding="utf-8")
        shutil.copymode(src, dst)

    print("\nCreate these two T3 scheduled tasks by hand (schedule_task); this skill does not create them.\n")
    for rel in SCHEDULES:
        print((target / rel).read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
