#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyyaml"]
# ///
"""Update an orchestrator state file (state/<TASK-ID>.yaml) without hand-editing YAML.

Subcommands:
  run-add     append a run to the ledger (fails if the id exists)
  run-set     set fields on an existing run:        run-set --task ABC-123 --id <run> state=completed result=clean finished=now
  set         set top-level or dotted fields:       set --task ABC-123 status=reviewing current.next_step="..."
  task-set    set fields on an epic task:           task-set --task ABC-123 --epic 3 --id 3.4 state="in review"
  check-tick  increment unchanged_checks
  check-reset set unchanged_checks to 0, recording the reason in sync_notes
  validate    report schema problems and exit non-zero if any

Values are parsed as YAML scalars; the words `now` and `today` expand to the current
timestamp / date. Every change sets `updated` and, unless --no-render, re-renders
PROGRESS.md and PROGRESS-digest.md.

Round-trip is done with PyYAML: key order is preserved, YAML comments are NOT.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import (  # noqa: E402
    ENUMS, StateError, append_note, default_root, die, find_run, find_task, load_state,
    parse_assignments, parse_value, save_state, set_dotted, state_path, touch_updated,
    validate_enum, validate_state, lint_runs,
)

RUN_ENUM_FIELDS = {"kind": "run.kind", "state": "run.state", "result": "run.result"}
TOP_ENUM_FIELDS = {"status": "status"}


def _render(root: Path, quiet: bool) -> None:
    script = Path(__file__).resolve().parent / "render-progress.py"
    cmd = [sys.executable, str(script), "--root", str(root)]
    if quiet:
        cmd.append("--quiet")
    rc = subprocess.call(cmd)
    if rc != 0:
        print("warning: render-progress reported problems", file=sys.stderr)


def _load(root: Path, task: str):
    p = state_path(root, task)
    if not p.exists():
        raise StateError(f"no state file at {p}")
    return p, load_state(p)


def _apply(data: Dict[str, Any], assignments: Dict[str, Any], enum_map: Dict[str, str], prefix: str = "") -> None:
    for key, value in assignments.items():
        kind = enum_map.get(key)
        if kind:
            validate_enum(kind, value, f"{prefix}{key}")
        set_dotted(data, key, value)


def cmd_run_add(args, data):
    if find_run(data, args.id):
        raise StateError(f"run {args.id!r} already exists; use run-set")
    run: Dict[str, Any] = {"id": args.id, "kind": args.kind}
    for field in ("provider", "model", "effort"):
        v = getattr(args, field)
        if v:
            run[field] = v
    if args.skills:
        run["skills"] = [s.strip() for s in args.skills.split(",") if s.strip()]
    if args.task_id:
        run["task_id"] = args.task_id
    run["state"] = args.state
    run["started"] = parse_value(args.started)
    for field in ("range", "report", "notes"):
        v = getattr(args, field)
        if v:
            run[field] = v
    validate_enum("run.kind", run["kind"], "kind")
    validate_enum("run.state", run["state"], "state")
    data.setdefault("runs", []).append(run)
    return f"added run {args.id}"


def cmd_run_set(args, data):
    run = find_run(data, args.id)
    if run is None:
        raise StateError(f"run {args.id!r} not found")
    assignments = parse_assignments(args.pairs)
    _apply(run, assignments, RUN_ENUM_FIELDS, f"run {args.id}.")
    if assignments.get("state") in ("completed", "failed", "cancelled", "blocked") and not run.get("finished"):
        run["finished"] = parse_value("now")
    return f"updated run {args.id}: {', '.join(assignments)}"


def cmd_set(args, data):
    assignments = parse_assignments(args.pairs)
    for key in assignments:
        if key in ("runs", "epics"):
            raise StateError(f"use run-add/run-set/task-set for {key!r}")
    _apply(data, assignments, TOP_ENUM_FIELDS)
    return f"set {', '.join(assignments)}"


def cmd_task_set(args, data):
    task = find_task(data, args.epic, args.id)
    if task is None:
        if not args.create:
            raise StateError(f"task {args.id!r} in epic {args.epic!r} not found (use --create to add it)")
        epic = next((e for e in data.get("epics") or [] if str(e.get("id")) == str(args.epic)), None)
        if epic is None:
            epic = {"id": str(args.epic), "name": "", "state": "queued", "tasks": []}
            data.setdefault("epics", []).append(epic)
        task = {"id": str(args.id), "name": "", "owner": "", "state": "queued"}
        epic.setdefault("tasks", []).append(task)
    assignments = parse_assignments(args.pairs)
    _apply(task, assignments, {"state": "task.state"}, f"task {args.id}.")
    return f"updated task {args.id}: {', '.join(assignments)}"


def cmd_check_tick(args, data):
    n = int(data.get("unchanged_checks") or 0) + 1
    data["unchanged_checks"] = n
    return f"unchanged_checks = {n}"


def cmd_check_reset(args, data):
    data["unchanged_checks"] = 0
    append_note(data, "sync_notes", f"unchanged_checks reset to 0: {args.reason}")
    return "unchanged_checks = 0"


def main() -> int:
    # Global flags accepted both before and after the subcommand. The subparser copy uses
    # SUPPRESS defaults so it never overrides a value given before the subcommand.
    def _globals(parser: argparse.ArgumentParser, suppress: bool) -> None:
        d = argparse.SUPPRESS if suppress else None
        parser.add_argument("--root", type=Path, default=d if suppress else default_root(),
                            help="repo root (default: auto-detected)")
        parser.add_argument("--no-render", action="store_true", default=d if suppress else False,
                            help="do not re-render PROGRESS.md afterwards")
        parser.add_argument("--quiet", action="store_true", default=d if suppress else False)

    common = argparse.ArgumentParser(add_help=False)
    _globals(common, suppress=True)
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    _globals(ap, suppress=False)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("run-add", parents=[common], help="append a run")
    p.add_argument("--task", required=True)
    p.add_argument("--id", required=True)
    p.add_argument("--kind", required=True, choices=ENUMS["run.kind"])
    p.add_argument("--provider")
    p.add_argument("--model")
    p.add_argument("--effort")
    p.add_argument("--skills", help="comma separated")
    p.add_argument("--task-id", dest="task_id")
    p.add_argument("--state", default="running", choices=ENUMS["run.state"])
    p.add_argument("--started", default="now")
    p.add_argument("--range")
    p.add_argument("--report")
    p.add_argument("--notes")
    p.set_defaults(fn=cmd_run_add)

    p = sub.add_parser("run-set", parents=[common], help="set fields on a run")
    p.add_argument("--task", required=True)
    p.add_argument("--id", required=True)
    p.add_argument("pairs", nargs="+", metavar="key=value")
    p.set_defaults(fn=cmd_run_set)

    p = sub.add_parser("set", parents=[common], help="set top-level / dotted fields")
    p.add_argument("--task", required=True)
    p.add_argument("pairs", nargs="+", metavar="key=value")
    p.set_defaults(fn=cmd_set)

    p = sub.add_parser("task-set", parents=[common], help="set fields on an epic task")
    p.add_argument("--task", required=True)
    p.add_argument("--epic", required=True)
    p.add_argument("--id", required=True)
    p.add_argument("--create", action="store_true", help="create the task (and epic) if missing")
    p.add_argument("pairs", nargs="+", metavar="key=value")
    p.set_defaults(fn=cmd_task_set)

    p = sub.add_parser("check-tick", parents=[common], help="increment unchanged_checks")
    p.add_argument("--task", required=True)
    p.set_defaults(fn=cmd_check_tick)

    p = sub.add_parser("check-reset", parents=[common], help="reset unchanged_checks to 0")
    p.add_argument("--task", required=True)
    p.add_argument("--reason", required=True)
    p.set_defaults(fn=cmd_check_reset)

    p = sub.add_parser("validate", parents=[common], help="validate a state file")
    p.add_argument("--task", required=True)
    p.set_defaults(fn=None)

    args = ap.parse_args()
    root = args.root.resolve()
    try:
        path, data = _load(root, args.task)
        if args.cmd == "validate":
            problems = validate_state(data)
            for prob in problems:
                print(f"problem: {prob}")
            for warn in lint_runs(data):
                print(f"warning: {warn}")
            print("valid" if not problems else f"{len(problems)} problem(s)")
            return 1 if problems else 0
        msg = args.fn(args, data)
        problems = validate_state(data)
        if problems:
            raise StateError("; ".join(problems))
        touch_updated(data)
        save_state(path, data)
    except StateError as e:
        die(str(e))
    if not args.quiet:
        print(f"{args.task}: {msg}")
    if not args.no_render:
        _render(root, args.quiet)
    return 0


if __name__ == "__main__":
    sys.exit(main())
