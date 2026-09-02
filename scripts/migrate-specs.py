#!/usr/bin/env python3
"""Migrate unversioned docs/specs/*/features.json files to schema v2."""

import json
import os
import stat
import sys
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


def migrate_item(item, previous_id, one_at_a_time):
    if not isinstance(item, dict):
        raise ValueError("mini-feature must be an object")
    if "depends_on" in item:
        dependencies = item["depends_on"]
    elif "after" in item:
        dependencies = [item["after"]]
    elif one_at_a_time and previous_id is not None:
        dependencies = [previous_id]
    else:
        dependencies = []
    hints = item.get("files_hint", item.get("files", []))
    migrated = {
        "id": item.get("id"),
        "name": item.get("name"),
        "scenarios": item.get("scenarios"),
        "depends_on": dependencies,
        "parallel": item.get("parallel", False),
        "files_hint": hints,
        "max_files": item.get("max_files"),
        "max_loc": item.get("max_loc"),
        "status": item.get("status"),
        "verified_by_human": item.get("verified_by_human", "skipped"),
    }
    for key, value in item.items():
        if key not in migrated and key not in {"after", "files"}:
            migrated[key] = value
    return migrated


def migrate(data):
    if not isinstance(data, dict):
        raise ValueError("root must be an object")
    version = data.get("schema_version")
    if version == 2:
        return data
    if "schema_version" in data:
        raise ValueError(f"unsupported schema_version {version!r}")
    items = data.get("mini_features")
    if not isinstance(items, list):
        raise ValueError("mini_features must be a list")
    rules = data.get("rules") or {}
    if not isinstance(rules, dict):
        raise ValueError("rules must be an object")
    one_at_a_time = bool(rules.get("one_at_a_time"))
    migrated_items = []
    previous_id = None
    for item in items:
        migrated_items.append(migrate_item(item, previous_id, one_at_a_time))
        previous_id = item.get("id") if isinstance(item, dict) else None

    result = {"schema_version": 2}
    result.update({key: value for key, value in data.items() if key not in {"schema_version", "mini_features"}})
    result["mini_features"] = migrated_items
    return result


def write_atomic(path, text):
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        os.fchmod(descriptor, stat.S_IMODE(path.stat().st_mode))
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(text)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def main():
    paths = [Path(value).resolve() for value in sys.argv[1:]]
    if not paths:
        paths = sorted(REPO.glob("docs/specs/*/features.json"))
    if not paths:
        print("SPEC MIGRATION FAILED:\n  - no features.json files found")
        return 1

    planned = []
    errors = []
    for path in paths:
        try:
            before = path.read_text(encoding="utf-8")
            data = json.loads(before)
            after = (
                before
                if isinstance(data, dict) and data.get("schema_version") == 2
                else json.dumps(migrate(data), indent=2) + "\n"
            )
            planned.append((path, before, after))
        except (OSError, json.JSONDecodeError, ValueError) as exc:
            errors.append(f"{path}: {exc}")
    if errors:
        print("SPEC MIGRATION FAILED:")
        for error in errors:
            print(f"  - {error}")
        return 1

    changed = 0
    for path, before, after in planned:
        if before != after:
            write_atomic(path, after)
            changed += 1
    print(f"spec ledgers migrated: {changed}; unchanged: {len(planned) - changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
