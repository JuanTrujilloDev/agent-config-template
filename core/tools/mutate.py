<!-- requires: enforce_mutation_testing -->
#!/usr/bin/env python3
"""Minimal, dependency-free mutation tester.

Usage:
    python3 tools/mutate.py <path/to/file.py> [-- <test command>]

Injects small behavioural defects (mutants) into the target file one at a time,
runs the test suite after each, and reports how many mutants the tests killed.
A *surviving* mutant is a defect no test caught — a hole in the net. The
threshold lives in the spec (default 80%). No third-party dependencies; requires
Python 3.9+ for `ast.unparse`.
"""
import ast
import subprocess
import sys

DEFAULT_TEST_CMD = "{{test_cmd}}".strip() or "pytest -q"

ARITH = {ast.Add: ast.Sub, ast.Sub: ast.Add, ast.Mult: ast.Div, ast.Div: ast.Mult}
CMP = {ast.Lt: ast.Gt, ast.Gt: ast.Lt, ast.LtE: ast.GtE, ast.GtE: ast.LtE,
       ast.Eq: ast.NotEq, ast.NotEq: ast.Eq}
BOOL = {ast.And: ast.Or, ast.Or: ast.And}


def find_sites(tree):
    """Return a list of mutable nodes paired with their mutation kind."""
    sites = []
    for node in ast.walk(tree):
        if isinstance(node, ast.BinOp) and type(node.op) in ARITH:
            sites.append((node, "op"))
        elif isinstance(node, ast.Compare) and len(node.ops) == 1 and type(node.ops[0]) in CMP:
            sites.append((node, "cmp"))
        elif isinstance(node, ast.BoolOp) and type(node.op) in BOOL:
            sites.append((node, "bool"))
        elif isinstance(node, ast.Constant) and isinstance(node.value, bool):
            sites.append((node, "const"))
    return sites


def mutate(node, kind):
    """Apply the mutation in place; return a token to revert it."""
    if kind == "op":
        old = node.op; node.op = ARITH[type(old)](); return old
    if kind == "cmp":
        old = node.ops[0]; node.ops[0] = CMP[type(old)](); return old
    if kind == "bool":
        old = node.op; node.op = BOOL[type(old)](); return old
    old = node.value; node.value = not node.value; return old


def revert(node, kind, old):
    if kind == "op":
        node.op = old
    elif kind == "cmp":
        node.ops[0] = old
    elif kind == "bool":
        node.op = old
    else:
        node.value = old


def main():
    args = sys.argv[1:]
    if not args:
        print("usage: mutate.py <file.py> [-- <test command>]", file=sys.stderr)
        sys.exit(2)
    target = args[0]
    test_cmd = DEFAULT_TEST_CMD
    if "--" in args:
        test_cmd = " ".join(args[args.index("--") + 1:]).strip() or test_cmd

    original = open(target, encoding="utf-8").read()
    tree = ast.parse(original)
    sites = find_sites(tree)
    if not sites:
        print("no mutation sites found"); sys.exit(0)

    killed = survived = 0
    survivors = []
    try:
        for node, kind in sites:
            old = mutate(node, kind)
            try:
                mutated_src = ast.unparse(tree)
            except Exception:
                revert(node, kind, old); continue
            open(target, "w", encoding="utf-8").write(mutated_src)
            rc = subprocess.run(test_cmd, shell=True, capture_output=True).returncode
            if rc != 0:
                killed += 1
            else:
                survived += 1
                survivors.append((getattr(node, "lineno", "?"), kind))
            revert(node, kind, old)
            open(target, "w", encoding="utf-8").write(original)
    finally:
        open(target, "w", encoding="utf-8").write(original)

    total = killed + survived
    pct = (killed / total * 100) if total else 100.0
    print(f"mutants: {total}  killed: {killed}  survived: {survived}  score: {pct:.0f}%")
    for line, kind in survivors:
        print(f"  survivor line {line} ({kind}) — no test failed on this defect")
    sys.exit(0 if survived == 0 else 1)


if __name__ == "__main__":
    main()
