#!/usr/bin/env python3
"""Validate docs/specs/*/features.json with Python's standard library."""

import json
import re
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCENARIO = re.compile(r"@s[1-9][0-9]*")
NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*$")
STATUSES = {"pending", "spec_ready", "in_progress", "done", "blocked"}
VERIFICATIONS = {"yes", "no", "skipped"}
V2_FIELDS = {
    "id",
    "name",
    "scenarios",
    "depends_on",
    "parallel",
    "files_hint",
    "max_files",
    "max_loc",
    "status",
    "verified_by_human",
}
LEGACY_FIELDS = {"id", "name", "scenarios", "max_files", "max_loc", "status"}
ALLOW_LEGACY = True


def label(path):
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def contract_scenarios(path):
    spec_dir = path.parent
    sources = [spec_dir / "contract.md", *sorted((spec_dir / "features").glob("*.feature"))]
    found = set()
    for source in sources:
        if not source.is_file():
            continue
        text = source.read_text(encoding="utf-8")
        pattern = SCENARIO if source.suffix == ".feature" else re.compile(r"^\s*-\s+(?:\*\*)?(@s[1-9][0-9]*)", re.M)
        found.update(match.group(1) if match.lastindex else match.group() for match in pattern.finditer(text))
    return found


def validate_item(item, index, strict, known_scenarios, errors):
    where = f"mini_features[{index}]"
    if not isinstance(item, dict):
        errors.append(f"{where}: expected object")
        return None

    required = V2_FIELDS if strict else LEGACY_FIELDS
    for field in sorted(required - item.keys()):
        errors.append(f"{where}: missing {field}")

    mf_id = item.get("id")
    if type(mf_id) is not int or mf_id < 1:
        errors.append(f"{where}.id: expected positive integer")

    name = item.get("name")
    if not isinstance(name, str) or not NAME.fullmatch(name):
        errors.append(f"{where}.name: {name!r} is not kebab-case")

    scenarios = item.get("scenarios")
    if not isinstance(scenarios, list) or not scenarios:
        errors.append(f"{where}.scenarios: expected non-empty list")
    else:
        seen = set()
        for scenario in scenarios:
            if not isinstance(scenario, str) or not SCENARIO.fullmatch(scenario):
                errors.append(f"{where}.scenarios: invalid scenario {scenario!r}")
            elif scenario in seen:
                errors.append(f"{where}.scenarios: duplicate scenario {scenario}")
            elif scenario not in known_scenarios:
                errors.append(f"{where}.scenarios: undefined scenario {scenario}")
            seen.add(scenario)

    for field in ("max_files", "max_loc"):
        value = item.get(field)
        if type(value) is not int or value < 1:
            errors.append(f"{where}.{field}: expected positive integer")

    status = item.get("status")
    if not isinstance(status, str) or status not in STATUSES:
        errors.append(f"{where}.status: invalid status {status!r}")

    if strict:
        dependencies = item.get("depends_on")
        if not isinstance(dependencies, list) or any(type(dep) is not int for dep in dependencies):
            errors.append(f"{where}.depends_on: expected integer list")
        elif len(dependencies) != len(set(dependencies)):
            errors.append(f"{where}.depends_on: duplicate dependency")
        if type(item.get("parallel")) is not bool:
            errors.append(f"{where}.parallel: expected boolean")
        hints = item.get("files_hint")
        if not isinstance(hints, list) or any(not isinstance(hint, str) for hint in hints):
            errors.append(f"{where}.files_hint: expected string list")
        verification = item.get("verified_by_human")
        if not isinstance(verification, str) or verification not in VERIFICATIONS:
            errors.append(f"{where}.verified_by_human: expected yes, no, or skipped")
    return item


def validate_dependencies(items, errors):
    ids = {item["id"] for item in items if type(item.get("id")) is int}
    graph = {}
    for item in items:
        mf_id = item.get("id")
        dependencies = item.get("depends_on")
        if (
            type(mf_id) is not int
            or not isinstance(dependencies, list)
            or any(type(dependency) is not int for dependency in dependencies)
        ):
            continue
        graph[mf_id] = [dep for dep in dependencies if type(dep) is int]
        if mf_id in dependencies:
            errors.append(f"mini-feature {mf_id}: self-dependency")
        for dependency in dependencies:
            if dependency not in ids:
                errors.append(f"mini-feature {mf_id}: unknown dependency {dependency}")

    visiting = set()
    visited = set()

    def visit(node):
        if node in visiting:
            return True
        if node in visited:
            return False
        visiting.add(node)
        cycle = any(dependency in graph and visit(dependency) for dependency in graph.get(node, []))
        visiting.remove(node)
        visited.add(node)
        return cycle

    if any(visit(node) for node in graph):
        errors.append("dependency cycle detected")


def validate(path):
    errors = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"cannot read JSON: {exc}"], False
    if not isinstance(data, dict):
        return ["root: expected object"], False

    strict = "schema_version" in data
    schema_version = data.get("schema_version")
    if strict and schema_version != 2:
        errors.append(f"schema_version: unsupported version {schema_version!r}")
    if not strict and not ALLOW_LEGACY:
        errors.append("schema_version: missing")
    if not isinstance(data.get("feature"), str) or not data.get("feature"):
        errors.append("feature: expected non-empty string")
    items = data.get("mini_features")
    if not isinstance(items, list) or not items:
        errors.append("mini_features: expected non-empty list")
        return errors, strict

    known_scenarios = contract_scenarios(path)
    if not known_scenarios:
        errors.append("contract: no scenarios found")
    valid_items = []
    for index, raw_item in enumerate(items):
        item = validate_item(raw_item, index, strict, known_scenarios, errors)
        if item is not None:
            valid_items.append(item)

    ids = [item.get("id") for item in valid_items if type(item.get("id")) is int]
    names = [item.get("name") for item in valid_items if isinstance(item.get("name"), str)]
    scenarios = [
        scenario
        for item in valid_items
        if isinstance(item.get("scenarios"), list)
        for scenario in item["scenarios"]
        if isinstance(scenario, str)
    ]
    for value in set(ids):
        if ids.count(value) > 1:
            errors.append(f"duplicate id: {value!r}")
    for value in set(names):
        if names.count(value) > 1:
            errors.append(f"duplicate name: {value!r}")
    for value in set(scenarios):
        if scenarios.count(value) > 1:
            errors.append(f"duplicate scenario across mini-features: {value!r}")
    if strict:
        validate_dependencies(valid_items, errors)
    return errors, strict


def main():
    paths = [Path(value).resolve() for value in sys.argv[1:]]
    if not paths:
        paths = sorted(REPO.glob("docs/specs/*/features.json"))
    if not paths:
        print("SPEC VALIDATION FAILED:\n  - no features.json files found")
        return 1

    failures = []
    strict_count = 0
    for path in paths:
        errors, strict = validate(path)
        strict_count += strict
        failures.extend(f"{label(path)}: {error}" for error in errors)
    if failures:
        print("SPEC VALIDATION FAILED:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"spec ledgers valid: {len(paths)} ({strict_count} schema v2, {len(paths) - strict_count} legacy)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
