#!/usr/bin/env python3
"""Fail when a whole-file override drops a source H2 without an exact waiver."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
PAIRS = (
    ("plugin/commands/feature.md", "hosts/codex/skills/feature/SKILL.md"),
    ("plugin/skills/port-config/SKILL.md", "hosts/codex/skills/port-config/SKILL.md"),
    ("plugin/skills/sdd-workflow/SKILL.md", "hosts/codex/skills/sdd-workflow/SKILL.md"),
    ("plugin/commands/setup-companions.md", "hosts/codex/skills/setup-companions/SKILL.md"),
    ("core/.claude/rules/patterns.md", "plugin/skills/patterns/SKILL.md"),
    ("core/.claude/rules/principles.md", "plugin/skills/principles/SKILL.md"),
)
MARKER_TOKEN = "override-ignore-h2"
MARKER = re.compile(r"<!-- override-ignore-h2: (.+) -->")


def read(path):
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise ValueError(f'cannot read "{path}": {error.strerror}') from error


def headings(text):
    return [line[3:] for line in text.splitlines() if line.startswith("## ")]


def check_pair(source, override):
    try:
        source_text = read(source)
        override_text = read(override)
    except ValueError as error:
        return [f"override drift: {source} -> {override}: {error}"]

    source_h2 = headings(source_text)
    override_h2 = set(headings(override_text))
    ignored = set()
    errors = []

    for line_number, line in enumerate(override_text.splitlines(), 1):
        if MARKER_TOKEN not in line:
            continue
        match = MARKER.fullmatch(line.strip())
        if not match:
            errors.append(
                f"override drift: {source} -> {override}:{line_number}: malformed {MARKER_TOKEN} marker"
            )
            continue
        heading = match.group(1)
        if heading not in source_h2:
            errors.append(
                f'override drift: {source} -> {override}:{line_number}: marker names unknown source H2 "{heading}"'
            )
        elif heading in override_h2:
            errors.append(
                f'override drift: {source} -> {override}:{line_number}: stale marker for present H2 "{heading}"'
            )
        elif heading in ignored:
            errors.append(
                f'override drift: {source} -> {override}:{line_number}: duplicate marker for H2 "{heading}"'
            )
        else:
            ignored.add(heading)

    for heading in source_h2:
        if heading not in override_h2 and heading not in ignored:
            errors.append(
                f'override drift: {source} -> {override}: missing H2 "{heading}"'
            )
    return errors


def main(argv):
    if not argv:
        pairs = [(ROOT / source, ROOT / override) for source, override in PAIRS]
    elif len(argv) == 2:
        pairs = [(Path(argv[0]), Path(argv[1]))]
    else:
        print(f"usage: {Path(sys.argv[0]).name} [SOURCE OVERRIDE]", file=sys.stderr)
        return 2

    errors = [error for pair in pairs for error in check_pair(*pair)]
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
