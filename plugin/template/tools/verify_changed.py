#!/usr/bin/env python3
"""Check only the lines a change adds: the Deslop rule, last-resort tries, the architecture map.

Usage:
  python3 tools/verify_changed.py                 # working tree against HEAD
  python3 tools/verify_changed.py --base main     # the branch since its merge-base with main
  python3 tools/verify_changed.py --hook          # Claude Code Stop hook (exit 2 asks for a fix)
  python3 tools/verify_changed.py src/a.py        # only these files
  python3 tools/verify_changed.py --slice docs/epics/X/slices/2.md   # on a detached HEAD (CI)

Python files get an AST pass (nested if, nested ternary, block depth over 2, new try not listed
under `## Last-resort error handling` in the current slice file, new comments outside the keep
list, a module breaking its `.claude/rules/architecture-map.md` row) plus ruff's deslop rules when
ruff is installed. JavaScript and TypeScript files get ESLint's deslop rules when ESLint is
installed. Legacy lines are never checked. Stdlib only.
"""

from __future__ import annotations

import argparse
import ast
import fnmatch
import io
import json
import re
import shutil
import subprocess
import sys
import tokenize
from pathlib import Path

SOURCE_DIRS = ["{{src_dir}}"{{#has_frontend}}, "{{frontend_dir}}"{{/has_frontend}}]
PY_SUFFIXES = {".py"}
JS_SUFFIXES = {".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx"}
MAX_DEPTH = 2
MAX_COMPLEXITY = 8
RUFF_RULES = "ERA001,BLE001,S110,S112,TRY203,C901,PLR0911,PLR0912,SIM102,RET505"
ESLINT_RULES = [
    f"complexity:[error,{MAX_COMPLEXITY}]",
    f"max-depth:[error,{MAX_DEPTH}]",
    "no-else-return:error",
    "no-empty:error",
    "no-nested-ternary:error",
    'no-restricted-syntax:[error,{"selector":"IfStatement > BlockStatement > IfStatement",'
    '"message":"nested if; use a guard clause"},{"selector":"TryStatement",'
    '"message":"new try; list it under Last-resort error handling in the slice or remove it"}]',
]
KEEP_COMMENT = re.compile(
    r"#\s*(noqa|type:|pragma|pylint:|fmt:|isort:|mypy:|ruff:|nosec)|https?://|SPDX-License|Copyright",
    re.IGNORECASE,
)
EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")
BLOCKS = tuple(getattr(ast, n) for n in ("If", "For", "AsyncFor", "While", "With", "AsyncWith", "Try", "TryStar", "Match") if hasattr(ast, n))
TRY_NODES = tuple(getattr(ast, n) for n in ("Try", "TryStar") if hasattr(ast, n))
MAP_CHECK = re.compile(r"^max (\d+) class(?:es)?(?: based on (\w+))?$|^no classes$")


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def base_ref(repo: Path, base: str | None) -> str:
    if base:
        return git(repo, "merge-base", base, "HEAD").strip()
    has_head = subprocess.run(["git", "rev-parse", "--verify", "-q", "HEAD"], cwd=repo, capture_output=True)
    return "HEAD" if has_head.returncode == 0 else EMPTY_TREE


DIFF = ("diff", "--no-color", "--no-ext-diff", "-M")


def changed_files(repo: Path, ref: str) -> list[Path]:
    dirs = [d.rstrip("/") for d in SOURCE_DIRS if d]
    tracked = git(repo, *DIFF, "--name-only", "--diff-filter=ACMR", "-z", ref, "--", *dirs)
    untracked = git(repo, "ls-files", "--others", "--exclude-standard", "-z", "--", *dirs)
    names = dict.fromkeys(n for n in (tracked + untracked).split("\0") if n)
    return [repo / n for n in names]


def renames(repo: Path, ref: str) -> dict[str, str]:
    fields = git(repo, *DIFF, "--name-status", "--diff-filter=R", "-z", ref).split("\0")
    return {fields[i + 2]: fields[i + 1] for i in range(0, len(fields) - 2, 3) if fields[i].startswith("R")}


def added_lines(repo: Path, path: Path, ref: str, moved: dict[str, str]) -> set[int]:
    rel = str(path.relative_to(repo))
    old = moved.get(rel, rel)
    known = subprocess.run(["git", "cat-file", "-e", f"{ref}:{old}"], cwd=repo, capture_output=True)
    if known.returncode:
        return set(range(1, len(path.read_text(encoding="utf-8").splitlines()) + 1))
    lines: set[int] = set()
    for line in git(repo, *DIFF, "--unified=0", ref, "--", *dict.fromkeys((old, rel))).splitlines():
        match = HUNK.match(line)
        if match:
            start, count = int(match.group(1)), int(match.group(2) or "1")
            lines.update(range(start, start + count))
    return lines


def current_slice(repo: Path, chosen: Path | None, notes: list[str]) -> str:
    if chosen:
        return chosen.read_text(encoding="utf-8")
    head = subprocess.run(["git", "symbolic-ref", "--short", "-q", "HEAD"], cwd=repo, text=True, capture_output=True)
    branch = head.stdout.strip()
    if not branch:
        notes.append("detached HEAD: pass --slice <slice file> so its last-resort tries count")
        return ""
    pattern = re.compile(r"^- Branch: `" + re.escape(branch) + "`", re.M)
    for path in sorted(repo.glob("docs/epics/*/slices/*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        if re.fullmatch(r"\d+\.md", path.name) and pattern.search(text):
            return text
    return ""


def table_rows(text: str, heading: str) -> list[list[str]]:
    section = re.search(r"^## " + re.escape(heading) + r"\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    lines = (section.group(1) if section else "").splitlines()
    rows = [re.split(r"(?<!\\)\|", line.strip().strip("|")) for line in lines if line.strip().startswith("|")]
    cells = [[c.replace("\\|", "|").strip().strip("`") for c in row] for row in rows if len(row) > 1]
    return [row for row in cells[1:] if not set(row[0]) <= set("-: ")]


def last_resort(slice_text: str) -> set[tuple[str, str]]:
    rows = table_rows(slice_text, "Last-resort error handling")
    return {(row[0], row[1].removesuffix("()").rsplit(".", 1)[-1]) for row in rows if len(row) > 1}


def map_rules(repo: Path) -> list[tuple[str, str, re.Match]]:
    path = repo / ".claude/rules/architecture-map.md"
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    rules = []
    for row in table_rows(text, "Map"):
        check = MAP_CHECK.match(row[-1]) if len(row) > 2 else None
        if check:
            rules.append((row[0], row[1], check))
    return rules


class Shape(ast.NodeVisitor):
    def __init__(self, rel: str, source: str, added: set[int], allowed: set[tuple[str, str]]) -> None:
        self.rel, self.lines, self.added, self.allowed = rel, source.splitlines(), added, allowed
        self.function, self.stack, self.elifs, self.ternary = "", [], set(), 0
        self.errors: list[str] = []

    def error(self, node: ast.AST, message: str) -> None:
        if node.lineno in self.added:
            self.errors.append(f"{self.rel}:{node.lineno}: {message}")

    def visit_FunctionDef(self, node: ast.FunctionDef | ast.AsyncFunctionDef) -> None:
        outer = (self.function, self.stack)
        self.function, self.stack = node.name, []
        self.generic_visit(node)
        self.function, self.stack = outer

    visit_AsyncFunctionDef = visit_FunctionDef

    def enter(self, node: ast.stmt) -> None:
        if self.function and len(self.stack) >= MAX_DEPTH:
            self.error(node, f"block depth {len(self.stack) + 1} > {MAX_DEPTH}; return early or extract a function")
        if isinstance(node, TRY_NODES) and (self.rel, self.function) not in self.allowed:
            self.error(node, f"new try in {self.function or '<module>'}; list it under Last-resort error handling in the slice or remove it")

    def generic_visit(self, node: ast.AST) -> None:
        if not isinstance(node, BLOCKS):
            super().generic_visit(node)
            return
        self.enter(node)
        self.stack.append(node)
        super().generic_visit(node)
        self.stack.pop()

    def visit_If(self, node: ast.If) -> None:
        is_elif = id(node) in self.elifs
        if not is_elif:
            if self.stack and isinstance(self.stack[-1], ast.If):
                self.error(node, "nested if; use a guard clause")
            self.enter(node)
        self.visit(node.test)
        self.stack.append(node)
        for child in node.body:
            self.visit(child)
        self.stack.pop()
        tail = node.orelse[0] if len(node.orelse) == 1 else None
        if isinstance(tail, ast.If) and self.lines[tail.lineno - 1].lstrip().startswith("elif"):
            self.elifs.add(id(tail))
            self.visit(node.orelse[0])
            return
        self.stack.append(node)
        for child in node.orelse:
            self.visit(child)
        self.stack.pop()

    def visit_IfExp(self, node: ast.IfExp) -> None:
        if self.ternary:
            self.error(node, "nested ternary")
        self.ternary += 1
        super().generic_visit(node)
        self.ternary -= 1


def comment_errors(rel: str, source: str, added: set[int]) -> list[str]:
    errors = []
    for token in tokenize.generate_tokens(io.StringIO(source).readline):
        line = token.start[0]
        if token.type != tokenize.COMMENT or line not in added:
            continue
        if (line <= 2 and token.string.startswith(("#!", "# -*-"))) or KEEP_COMMENT.search(token.string):
            continue
        errors.append(f"{rel}:{line}: new comment; name things so it is not needed (keep list: tool directives, license, outside link)")
    return errors


def map_errors(rel: str, tree: ast.Module, added: set[int], rules: list) -> list[str]:
    classes = [n for n in tree.body if isinstance(n, ast.ClassDef)]
    for kind, glob, check in rules:
        if Path(rel).name == "__init__.py" or not fnmatch.fnmatch(rel, glob):
            continue
        limit, base = (0, None) if check.group(0) == "no classes" else (int(check.group(1)), check.group(2))
        counted = [c for c in classes if base is None or any(_last(b) == base for b in c.bases)]
        if len(counted) > limit and any(c.lineno in added for c in counted):
            return [f"{rel}:{counted[limit].lineno}: {len(counted)} classes where the map row \"{kind}\" allows {limit}; see .claude/rules/architecture-map.md"]
    return []


def _last(node: ast.expr) -> str:
    return node.attr if isinstance(node, ast.Attribute) else getattr(node, "id", "")


def python_errors(repo: Path, path: Path, added: set[int], allowed: set, rules: list) -> list[str]:
    rel = str(path.relative_to(repo))
    source = path.read_text(encoding="utf-8")
    try:
        tree = ast.parse(source, filename=rel)
    except SyntaxError as error:
        return [f"{rel}:{error.lineno}: could not parse: {error.msg}"]
    shape = Shape(rel, source, added, allowed)
    shape.visit(tree)
    return shape.errors + comment_errors(rel, source, added) + map_errors(rel, tree, added, rules)


def tool(repo: Path, local: str, name: str) -> str:
    candidate = repo / local
    return str(candidate) if candidate.is_file() else shutil.which(name) or ""


def ruff_errors(repo: Path, files: list[Path], added: dict[Path, set[int]], notes: list[str]) -> list[str]:
    ruff = tool(repo, ".venv/bin/ruff", "ruff")
    if not files or not ruff:
        notes.extend(["ruff not installed; skipped its deslop rules"] if files else [])
        return []
    command = [ruff, "check", "--no-fix", "--output-format", "json", "--select", RUFF_RULES,
               "--config", f"lint.mccabe.max-complexity = {MAX_COMPLEXITY}", *map(str, files)]
    result = subprocess.run(command, cwd=repo, text=True, capture_output=True, check=False)
    try:
        messages = json.loads(result.stdout or "[]")
    except json.JSONDecodeError:
        return [f"ruff failed: {(result.stderr or result.stdout).strip()}"]
    hits = [(Path(m["filename"]).resolve(), m["location"]["row"], m) for m in messages]
    return [f"{p.relative_to(repo)}:{row}: {m['code']} {m['message']}" for p, row, m in hits if row in added.get(p, set())]


def eslint_errors(repo: Path, files: list[Path], added: dict[Path, set[int]], allowed_files: set[str], notes: list[str]) -> list[str]:
    eslint = tool(repo, "node_modules/.bin/eslint", "eslint")
    if not files or not eslint:
        notes.extend(["eslint not installed; skipped its deslop rules"] if files else [])
        return []
    command = [eslint, "--format", "json", *[a for r in ESLINT_RULES for a in ("--rule", r)], *map(str, files)]
    result = subprocess.run(command, cwd=repo, text=True, capture_output=True, check=False)
    try:
        reports = json.loads(result.stdout or "[]")
    except json.JSONDecodeError:
        notes.append(f"eslint could not run here: {(result.stderr or result.stdout).strip()[:200]}")
        return []
    errors = []
    for report in reports:
        path = Path(report["filePath"]).resolve()
        rel = str(path.relative_to(repo))
        for m in report.get("messages", []):
            line = int(m.get("line") or 0)
            is_try = "new try" in m.get("message", "")
            if m.get("severity") == 2 and line in added.get(path, set()) and not (is_try and rel in allowed_files):
                errors.append(f"{rel}:{line}: {m.get('ruleId') or 'parse'} {m['message']}")
    return errors


def verify(repo: Path, paths: list[Path], base: str | None, chosen: Path | None) -> tuple[int, list[str], list[str]]:
    ref = base_ref(repo, base)
    files = [p.resolve() for p in (paths or changed_files(repo, ref)) if p.is_file()]
    py = [p for p in files if p.suffix in PY_SUFFIXES]
    js = [p for p in files if p.suffix in JS_SUFFIXES]
    moved = renames(repo, ref)
    added = {p: added_lines(repo, p, ref, moved) for p in py + js}
    notes: list[str] = []
    allowed = last_resort(current_slice(repo, chosen, notes))
    rules = map_rules(repo)
    errors: list[str] = []
    for path in py:
        errors.extend(python_errors(repo, path, added[path], allowed, rules))
    errors.extend(ruff_errors(repo, py, added, notes))
    errors.extend(eslint_errors(repo, js, added, {f for f, _ in allowed}, notes))
    return len(files), sorted(dict.fromkeys(errors)), notes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--hook", action="store_true")
    parser.add_argument("--base")
    parser.add_argument("--slice", type=Path)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()
    top = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=args.repo, text=True, capture_output=True)
    if top.returncode:
        print("{}" if args.hook else "[verify-changed] not a git repository; nothing to check")
        return 0
    repo = Path(top.stdout.strip()).resolve()
    payload = json.loads(sys.stdin.read() or "{}") if args.hook else {}
    count, errors, notes = verify(repo, [Path.cwd() / p for p in args.paths], args.base, args.slice)
    for note in notes:
        print(f"[verify-changed] note: {note}", file=sys.stderr)
    if not errors:
        print(f"[verify-changed] passed: {count} changed file(s)" if not args.hook else "{}")
        return 0
    print("[verify-changed] failed on added lines:", *errors, sep="\n  - ", file=sys.stderr)
    if args.hook and payload.get("stop_hook_active"):
        return 0
    return 2 if args.hook else 1


if __name__ == "__main__":
    sys.exit(main())
