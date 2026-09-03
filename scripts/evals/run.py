#!/usr/bin/env python3
"""Validate and optionally run deterministic cross-host behavior evaluations."""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG = Path(__file__).with_name("cases.jsonl")
HOSTS = {
    "claude": ("claude", "EVAL_CLAUDE_BIN"),
    "codex": ("codex", "EVAL_CODEX_BIN"),
    "cursor": ("cursor-agent", "EVAL_CURSOR_BIN"),
    "grok": ("grok", "EVAL_GROK_BIN"),
}
MANUAL_CASES = {
    "adaptive-skills:@s17",
    "adaptive-skills:@s23",
    "adaptive-skills:@s24",
    "adaptive-skills:@s39",
    "adaptive-skills:@s66",
}
AUTH_WORDS = ("authentication", "authenticate", "unauthorized", "api key", "login required", "401")


def safe_repo_file(value, label):
    path = (ROOT / value).resolve()
    try:
        path.relative_to(ROOT)
    except ValueError as exc:
        raise ValueError(f"{label} escapes the repository") from exc
    if not path.is_file():
        raise ValueError(f"{label} does not exist: {value}")
    return path


def validate_rubric(rubric, where):
    if not isinstance(rubric, dict):
        raise ValueError(f"{where}.rubric must be an object")
    for key in ("required", "forbidden"):
        values = rubric.get(key)
        if not isinstance(values, list) or any(not isinstance(value, str) for value in values):
            raise ValueError(f"{where}.rubric.{key} must be a string list")
        for value in values:
            re.compile(value)
    lines = rubric.get("max_lines")
    if type(lines) is not int or lines < 1:
        raise ValueError(f"{where}.rubric.max_lines must be positive")
    files = rubric.get("files")
    if not isinstance(files, list):
        raise ValueError(f"{where}.rubric.files must be a list")
    for index, item in enumerate(files, 1):
        if not isinstance(item, dict) or set(item) - {"path", "contains"}:
            raise ValueError(f"{where}.rubric.files[{index}] is invalid")
        path = item.get("path")
        if not isinstance(path, str) or not path or Path(path).is_absolute() or ".." in Path(path).parts:
            raise ValueError(f"{where}.rubric.files[{index}].path is unsafe")
        if "contains" in item and not isinstance(item["contains"], str):
            raise ValueError(f"{where}.rubric.files[{index}].contains must be a string")


def load_catalog(path):
    cases = []
    seen = set()
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        where = f"{path}:{number}"
        try:
            case = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{where}: invalid JSON: {exc.msg}") from exc
        required = {"id", "legacy", "mode", "fixture", "prompt", "rubric"}
        if not isinstance(case, dict) or set(case) != required:
            raise ValueError(f"{where}: expected exactly {sorted(required)}")
        case_id = case["id"]
        if not isinstance(case_id, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", case_id):
            raise ValueError(f"{where}.id must be kebab-case")
        if case_id in seen:
            raise ValueError(f"{where}.id is duplicated: {case_id}")
        seen.add(case_id)
        if case["mode"] not in {"response", "workspace"}:
            raise ValueError(f"{where}.mode must be response or workspace")
        if not isinstance(case["legacy"], str) or not isinstance(case["prompt"], str) or not case["prompt"]:
            raise ValueError(f"{where}: legacy and prompt must be strings")
        if not isinstance(case["fixture"], str):
            raise ValueError(f"{where}.fixture must be a string")
        safe_repo_file(case["fixture"], f"{where}.fixture")
        validate_rubric(case["rubric"], where)
        cases.append(case)
    legacy = {case["legacy"] for case in cases if case["legacy"].startswith("adaptive-skills:")}
    if legacy != MANUAL_CASES:
        raise ValueError("catalog must cover the five current MANUAL scenarios exactly")
    if not any(case["mode"] == "workspace" for case in cases):
        raise ValueError("catalog needs at least one workspace workflow case")
    return cases


def executable(host):
    default, variable = HOSTS[host]
    requested = os.environ.get(variable, default)
    if os.sep in requested:
        path = Path(requested)
        return str(path) if path.is_file() and os.access(path, os.X_OK) else None
    return shutil.which(requested)


def host_argv(host, binary, prompt, mode):
    model = os.environ.get(f"EVAL_{host.upper()}_MODEL")
    if host == "claude":
        argv = [binary, "-p", prompt, "--output-format", "json"]
    elif host == "codex":
        sandbox = "workspace-write" if mode == "workspace" else "read-only"
        argv = [binary, "exec", "--json", "--ephemeral", "--sandbox", sandbox, prompt]
    elif host == "cursor":
        argv = [binary, "-p", prompt, "--output-format", "json"]
    else:
        argv = [binary, "--no-auto-update", "-p", prompt, "--output-format", "json"]
    if model:
        argv.extend(["--model", model])
    return argv


def response_text(stdout):
    objects = []
    try:
        objects.append(json.loads(stdout))
    except json.JSONDecodeError:
        for line in stdout.splitlines():
            try:
                objects.append(json.loads(line))
            except json.JSONDecodeError:
                continue

    def strings(value, accept_string=False):
        if isinstance(value, dict):
            for key in ("result", "text", "message", "content", "output"):
                if key in value:
                    yield from strings(value[key], True)
            for key, child in value.items():
                if key not in {"result", "text", "message", "content", "output"} and isinstance(
                    child, (dict, list)
                ):
                    yield from strings(child)
        elif isinstance(value, list):
            for child in value:
                yield from strings(child, accept_string)
        elif accept_string and isinstance(value, str) and value.strip():
            yield value.strip()

    found = []
    for obj in objects:
        found.extend(strings(obj, isinstance(obj, str)))
    if not found:
        raise ValueError("host returned no JSON response")
    return found[-1]


def grade(case, response, workspace):
    rubric = case["rubric"]
    failures = []
    flags = re.IGNORECASE | re.MULTILINE
    for pattern in rubric["required"]:
        if not re.search(pattern, response, flags):
            failures.append(f"missing required pattern: {pattern}")
    for pattern in rubric["forbidden"]:
        if re.search(pattern, response, flags):
            failures.append(f"matched forbidden pattern: {pattern}")
    if len(response.splitlines()) > rubric["max_lines"]:
        failures.append(f"response exceeds {rubric['max_lines']} lines")
    for expected in rubric["files"]:
        path = workspace / expected["path"]
        if not path.is_file():
            failures.append(f"missing file: {expected['path']}")
        elif expected.get("contains") not in (None, "") and expected["contains"] not in path.read_text(
            encoding="utf-8", errors="replace"
        ):
            failures.append(f"file content mismatch: {expected['path']}")
    return failures


def prepare_workspace(case, host, parent):
    target = parent / "project"
    fixture = safe_repo_file(case["fixture"], "fixture")
    completed = subprocess.run(
        ["bash", str(ROOT / "setup.sh"), "--target", str(target), "--answers", str(fixture), "--host", host],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(f"fixture render exited {completed.returncode}")
    if case["mode"] == "workspace":
        for argv in (["git", "init", "-q"], ["git", "checkout", "-q", "-b", "feature/eval-smoke"]):
            completed = subprocess.run(argv, cwd=target, capture_output=True, text=True, check=False)
            if completed.returncode:
                raise RuntimeError(f"fixture git setup exited {completed.returncode}")
    return target


def result(case, host, status, reason, started):
    return {
        "case": case["id"],
        "host": host,
        "status": status,
        "reason": reason,
        "duration_seconds": round(time.monotonic() - started, 3),
    }


def run_case(case, host, timeout):
    started = time.monotonic()
    binary = executable(host)
    if not binary:
        return result(case, host, "skip", "host executable unavailable", started)
    with tempfile.TemporaryDirectory(prefix="agent-config-eval-") as raw:
        try:
            workspace = prepare_workspace(case, host, Path(raw))
        except (RuntimeError, subprocess.TimeoutExpired) as exc:
            return result(case, host, "error", str(exc), started)
        argv = host_argv(host, binary, case["prompt"], case["mode"])
        try:
            completed = subprocess.run(
                argv, cwd=workspace, capture_output=True, text=True, timeout=timeout, check=False
            )
        except subprocess.TimeoutExpired:
            return result(case, host, "error", f"host timed out after {timeout}s", started)
        if completed.returncode:
            combined = f"{completed.stdout}\n{completed.stderr}".lower()
            if any(word in combined for word in AUTH_WORDS):
                return result(case, host, "skip", "authentication unavailable", started)
            return result(case, host, "error", f"host exited {completed.returncode}", started)
        try:
            response = response_text(completed.stdout)
        except ValueError as exc:
            return result(case, host, "error", str(exc), started)
        failures = grade(case, response, workspace)
        return result(case, host, "fail" if failures else "pass", "; ".join(failures) or "rubric passed", started)


def write_results(path, results):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(results, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def parser():
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    cli = argparse.ArgumentParser(description=__doc__)
    commands = cli.add_subparsers(dest="command", required=True)
    commands.add_parser("validate", parents=[common])
    commands.add_parser("list", parents=[common])
    run = commands.add_parser("run", parents=[common])
    run.add_argument("--host", action="append", choices=HOSTS, required=True)
    run.add_argument("--case", action="append", dest="case_ids")
    run.add_argument("--run", action="store_true", dest="execute")
    run.add_argument("--allow-writes", action="store_true")
    run.add_argument("--timeout", type=int, default=300)
    run.add_argument("--results", type=Path, default=ROOT / "eval-results/results.json")
    return cli


def main():
    args = parser().parse_args()
    try:
        cases = load_catalog(args.catalog.resolve())
    except (OSError, ValueError, re.error) as exc:
        print(f"eval catalog error: {exc}", file=sys.stderr)
        return 2
    if args.command == "validate":
        print(f"eval catalog valid: {len(cases)} cases")
        return 0
    if args.command == "list":
        for case in cases:
            print(case["id"])
        return 0
    selected = cases
    if args.case_ids:
        wanted = set(args.case_ids)
        selected = [case for case in cases if case["id"] in wanted]
        missing = wanted - {case["id"] for case in selected}
        if missing:
            print(f"unknown case: {', '.join(sorted(missing))}", file=sys.stderr)
            return 2
    if not 1 <= args.timeout <= 3600:
        print("--timeout must be between 1 and 3600", file=sys.stderr)
        return 2
    if args.execute and any(case["mode"] == "workspace" for case in selected) and not args.allow_writes:
        print("workspace cases require --run --allow-writes", file=sys.stderr)
        return 2
    if not args.execute:
        for host in args.host:
            for case in selected:
                print(f"PLAN {host} {case['id']} {case['mode']}")
        return 0
    results = [run_case(case, host, args.timeout) for host in args.host for case in selected]
    write_results(args.results, results)
    for item in results:
        print(f"{item['status'].upper()} {item['host']} {item['case']}: {item['reason']}")
    return 1 if any(item["status"] in {"fail", "error"} for item in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
