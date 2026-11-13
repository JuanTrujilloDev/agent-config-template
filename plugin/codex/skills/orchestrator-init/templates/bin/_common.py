"""Shared helpers for the bin/ scripts of this orchestrator folder.

Imported by the sibling scripts (the script directory is on sys.path when a
script runs). Standard library plus PyYAML only.
"""

from __future__ import annotations

import datetime as _dt
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml

STATE_DIRNAME = "state"
STATE_SKIP = {"SCHEMA.md", "EXAMPLE.yaml", "README.md"}

ENUMS: Dict[str, List[str]] = {
    "status": ["draft", "approved", "executing", "reviewing", "done", "paused", "cancelled"],
    # Column names of your tracker board, matched case-insensitively: edit this list to match yours.
    "tracker.state": ["Backlog", "ToDo", "To Do", "Open", "In progress", "In review", "Done", "Closed",
                      "Cancelled", "Canceled", "Archive"],
    "epic.state": ["queued", "executing", "in review", "done", "cancelled"],
    "task.state": ["queued", "executing", "in review", "blocked", "done", "cancelled"],
    "run.kind": [
        "execute", "review", "fix", "preflight", "research", "design", "learnings",
        "closeout", "publication", "sync", "diagnosis", "tests",
    ],
    "run.state": ["queued", "running", "completed", "failed", "cancelled", "blocked"],
    "run.result": ["clean", "changes_requested", "blocked", "inconclusive", "delivered", "n/a"],
}

# Filled by orchestrator-init; used in rendered progress and tracker comments.
APPROVER = "{{approver}}"
TRACKER = "{{tracker}}"


class StateError(Exception):
    pass


# --------------------------------------------------------------------------- paths

# The orchestrator folder is the parent of bin/, whatever it is named.
ORCH_DIR = Path(__file__).resolve().parents[1]


def default_root() -> Path:
    """Repo root: the parent of the orchestrator folder holding bin/."""
    return ORCH_DIR.parent


def orchestrator_dir(root: Path) -> Path:
    return Path(root) / ORCH_DIR.name


def state_dir(root: Path) -> Path:
    return orchestrator_dir(root) / STATE_DIRNAME


def state_path(root: Path, task: str) -> Path:
    task = task.strip()
    # Any tracker key that is safe as a file name: ABC-123, QA2-15, 123 (GitHub Issues).
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", task):
        raise StateError(f"task id must be letters, digits, - or _ (e.g. ABC-123 or 123), got {task!r}")
    return state_dir(root) / f"{task}.yaml"


def list_state_files(root: Path) -> List[Path]:
    d = state_dir(root)
    if not d.is_dir():
        return []
    out = []
    for p in sorted(d.iterdir()):
        if p.name in STATE_SKIP or p.suffix not in (".yaml", ".yml") or p.name.startswith("."):
            continue
        out.append(p)
    return out


# --------------------------------------------------------------------------- yaml

class _Dumper(yaml.SafeDumper):
    pass


def _str_representer(dumper: yaml.SafeDumper, data: str):
    if "\n" in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    if len(data) > 100 and " " in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style=">")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


_Dumper.add_representer(str, _str_representer)


def load_state(path: Path) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    if not isinstance(data, dict):
        raise StateError(f"{path}: top level must be a mapping")
    return data


def save_state(path: Path, data: Dict[str, Any]) -> None:
    """Write YAML preserving insertion (key) order. Comments are not preserved."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w", encoding="utf-8") as fh:
        yaml.dump(data, fh, Dumper=_Dumper, sort_keys=False, allow_unicode=True, width=100)
    os.replace(tmp, path)


def now_iso() -> str:
    """Current local time with UTC offset, seconds precision."""
    return _dt.datetime.now().astimezone().replace(microsecond=0).isoformat()


def today() -> str:
    return _dt.date.today().isoformat()


def touch_updated(data: Dict[str, Any]) -> None:
    data["updated"] = now_iso()


# --------------------------------------------------------------------------- validation

def validate_enum(kind: str, value: Any, where: str = "") -> None:
    if value is None:
        return
    allowed = ENUMS.get(kind)
    if allowed is None:
        return
    if kind == "tracker.state" and isinstance(value, str):
        # Boards differ in case ("In Progress", "Todo"); compare folded.
        allowed_folded = {a.casefold() for a in allowed}
        if value.casefold() in allowed_folded:
            return
    if value not in allowed:
        raise StateError(
            f"{where or kind}: {value!r} is not one of {allowed}"
        )


def validate_state(data: Dict[str, Any]) -> List[str]:
    """Return a list of problems (empty if valid)."""
    problems: List[str] = []

    def chk(kind: str, value: Any, where: str) -> None:
        try:
            validate_enum(kind, value, where)
        except StateError as e:
            problems.append(str(e))

    for key in ("task", "title", "plan", "status"):
        if not data.get(key):
            problems.append(f"missing required field {key!r}")
    chk("status", data.get("status"), "status")
    chk("tracker.state", (data.get("tracker") or {}).get("state"), "tracker.state")
    if "unchanged_checks" in data and not isinstance(data["unchanged_checks"], int):
        problems.append("unchanged_checks must be an integer")
    for epic in data.get("epics") or []:
        chk("epic.state", epic.get("state"), f"epic {epic.get('id')}.state")
        for task in epic.get("tasks") or []:
            chk("task.state", task.get("state"), f"task {task.get('id')}.state")
    seen = set()
    for run in data.get("runs") or []:
        rid = run.get("id")
        if not rid:
            problems.append("run without id")
        elif rid in seen:
            problems.append(f"duplicate run id {rid!r}")
        seen.add(rid)
        chk("run.kind", run.get("kind"), f"run {rid}.kind")
        chk("run.state", run.get("state"), f"run {rid}.state")
        chk("run.result", run.get("result"), f"run {rid}.result")
    return problems


# --------------------------------------------------------------------------- value parsing

def parse_value(raw: str) -> Any:
    """Parse a CLI value: 'now' -> timestamp, 'today' -> date, YAML scalars/lists otherwise."""
    if raw == "now":
        return now_iso()
    if raw == "today":
        return today()
    try:
        val = yaml.safe_load(raw)
    except yaml.YAMLError:
        return raw
    if val is None and raw.strip() not in ("", "null", "~"):
        return raw
    return val


def parse_assignments(pairs: List[str]) -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    for p in pairs:
        if "=" not in p:
            raise StateError(f"expected key=value, got {p!r}")
        k, v = p.split("=", 1)
        out[k.strip()] = parse_value(v)
    return out


def set_dotted(data: Dict[str, Any], dotted: str, value: Any) -> None:
    parts = dotted.split(".")
    cur: Any = data
    for part in parts[:-1]:
        if not isinstance(cur, dict):
            raise StateError(f"cannot descend into {part!r} in {dotted!r}")
        if part not in cur or cur[part] is None:
            cur[part] = {}
        cur = cur[part]
    if not isinstance(cur, dict):
        raise StateError(f"cannot set {dotted!r}: parent is not a mapping")
    cur[parts[-1]] = value


def find_run(data: Dict[str, Any], run_id: str) -> Optional[Dict[str, Any]]:
    for run in data.get("runs") or []:
        if run.get("id") == run_id:
            return run
    return None


def find_task(data: Dict[str, Any], epic_id: str, task_id: str) -> Optional[Dict[str, Any]]:
    for epic in data.get("epics") or []:
        if str(epic.get("id")) == str(epic_id):
            for task in epic.get("tasks") or []:
                if str(task.get("id")) == str(task_id):
                    return task
    return None


def append_note(data: Dict[str, Any], key: str, text: str) -> None:
    lst = data.get(key)
    if not isinstance(lst, list):
        lst = []
        data[key] = lst
    lst.append(f"{today()} {text}")


def die(msg: str, code: int = 1) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(code)

def lint_runs(data: Dict[str, Any], now: Any = None) -> List[str]:
    """Non-fatal warnings: runs still 'running' that look finished or stale (>24h)."""
    import datetime as _dt
    now = now or _dt.datetime.now(_dt.timezone.utc)
    warnings: List[str] = []
    for run in data.get("runs") or []:
        if run.get("state") != "running":
            continue
        rid = run.get("id")
        if run.get("finished"):
            warnings.append(f"run {rid}: state running but finished is set")
            continue
        started = run.get("started")
        try:
            ts = started if isinstance(started, _dt.datetime) else _dt.datetime.fromisoformat(str(started))
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=_dt.timezone.utc)
            if now - ts > _dt.timedelta(hours=24):
                warnings.append(f"run {rid}: running for more than 24h (started {started})")
        except (TypeError, ValueError):
            pass
    return warnings
