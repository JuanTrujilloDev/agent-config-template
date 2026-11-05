#!/usr/bin/env python3
"""Validate docs/epics/<ID>/epic.md and slices/<n>.md (python3 stdlib only).

Usage: validate-epics.py [PATH]   PATH = docs/epics (default) or one epic folder.

ERROR (exit 1): missing epic.md or a required section, a duplicate story id, a slice without
`- Layer:` / `- Stories covered:`, or any AC, TS, slice or test name that points at an unknown story.
WARN (exit 0): size guidance and shape hints — an epic with no stories, epic >120 lines, slice >60
lines or >5 stories, a story without exactly one AC and one TS, a TS over 5 lines, a missing source
header or Branch line.
Exit 2: an explicit PATH that does not exist. `archive/` folders are skipped. Only `slices/<n>.md`
are slices; reports beside them (`<n>.security.md`, `<n>.mutation.md`) are not checked.
"""
import re
import sys
from pathlib import Path

REQUIRED = ("Request", "Description", "Capability groups", "User Stories", "Acceptance Criteria", "Test Scenarios")
HEADER = re.compile(r"^<!-- .*source=\w+.* -->$")
ENTRY = re.compile(r"^- \*\*(T?S)(\d+)\*\*")
STORY_REF = re.compile(r"\bS(\d+)\b")
out = {"ERROR": 0, "WARN": 0}


def say(level, path, msg):
    out[level] += 1
    print(f"{level} {path}: {msg}")


def sections(text):
    """H2 title -> list of body lines."""
    found, current = {}, None
    for line in text.splitlines():
        if line.startswith("## "):
            current = found.setdefault(line[3:].strip(), [])
        elif current is not None:
            current.append(line)
    return found


def entries(lines, kind):
    """[(number, line_count)] for `- **S1**` / `- **TS1**` bullets; continuation lines count."""
    result = []
    for line in lines:
        m = ENTRY.match(line)
        if m:
            result.append([int(m.group(2)), 1] if m.group(1) == kind else None)
        elif result and result[-1] and line.strip() and not line.startswith(("-", "#")):
            result[-1][1] += 1
    return [tuple(e) for e in result if e]


def check_epic(folder, root):
    rel = lambda p: p.relative_to(root) if root in p.parents or p == root else p
    epic = folder / "epic.md"
    if not epic.is_file():
        say("ERROR", rel(folder), "no epic.md")
        return
    text = epic.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or not HEADER.match(lines[0]):
        say("WARN", rel(epic), "first line is not a `<!-- ... source=<plane|local|migrated|...> ... -->` header")
    if len(lines) > 120:
        say("WARN", rel(epic), f"{len(lines)} lines (guidance ≤120)")
    secs = sections(text)
    for name in REQUIRED:
        if name not in secs:
            say("ERROR", rel(epic), f"missing section `## {name}`")
    stories = [n for n, _ in entries(secs.get("User Stories", []), "S")]
    for n in sorted({n for n in stories if stories.count(n) > 1}):
        say("ERROR", rel(epic), f"story S{n} defined more than once")
    known = set(stories)
    if not known:
        say("WARN", rel(epic), "no `- **S<n>**` stories under `## User Stories`")
    for title, kind, label in (("Acceptance Criteria", "S", "AC"), ("Test Scenarios", "TS", "TS")):
        got = entries(secs.get(title, []), kind)
        nums = [n for n, _ in got]
        for n in sorted(set(nums) - known):
            say("ERROR", rel(epic), f"{label} names unknown story S{n}")
        for n in sorted(known):
            if nums.count(n) != 1:
                say("WARN", rel(epic), f"S{n} has {nums.count(n)} {label} entries (guidance: exactly one)")
        if kind == "TS":
            for n, size in got:
                if size > 5:
                    say("WARN", rel(epic), f"TS{n} spans {size} lines (guidance ≤5)")
    for path in sorted(p for p in (folder / "slices").glob("*.md") if re.fullmatch(r"\d+\.md", p.name)):
        check_slice(path, known, rel)


def check_slice(path, known, rel):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or not HEADER.match(lines[0]):
        say("WARN", rel(path), "first line is not a source header")
    if len(lines) > 60:
        say("WARN", rel(path), f"{len(lines)} lines (guidance ≤60)")
    if not re.search(r"^- Layer: \S", text, re.M):
        say("ERROR", rel(path), "missing `- Layer:` line")
    if not re.search(r"^- Branch: `", text, re.M):
        say("WARN", rel(path), "missing ``- Branch: `<branch>` `` line (the approved-tests lock keys on it)")
    covered = re.search(r"^- Stories covered: (.*)$", text, re.M)
    if not covered:
        say("ERROR", rel(path), "missing `- Stories covered:` line")
        return
    nums = [int(n) for n in STORY_REF.findall(covered.group(1))]
    if len(nums) > 5:
        say("WARN", rel(path), f"covers {len(nums)} stories (guidance ≤5)")
    tests = re.findall(r"\btest_S(\d+)_", "\n".join(sections(text).get("Tests", [])))
    for n in sorted(set(nums + [int(t) for t in tests]) - known):
        say("ERROR", rel(path), f"names unknown story S{n}")


def main():
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/epics")
    if len(sys.argv) > 1 and not target.exists():
        print(f"no such path: {target}", file=sys.stderr)
        return 2
    if (target / "epic.md").is_file():
        folders = [target]
    elif target.is_dir():
        folders = [d for d in sorted(target.iterdir()) if d.is_dir() and d.name != "archive"]
    else:
        print(f"no epics at {target}")
        return 0
    for folder in folders:
        check_epic(folder, target if folders != [target] else target.parent)
    print(f"{len(folders)} epic(s): {out['ERROR']} error(s), {out['WARN']} warning(s)")
    return 1 if out["ERROR"] else 0


if __name__ == "__main__":
    sys.exit(main())
