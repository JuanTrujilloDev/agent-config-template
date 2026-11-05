#!/usr/bin/env python3
"""Migrate v0.10 `docs/specs/<slug>/` folders to the v0.11 `docs/epics/` layout (python3 stdlib only).

Usage: migrate.py [--root DIR] [--apply] [SLUG ...]

Without --apply it prints the plan and writes nothing; it still parses and renders every open
spec, so one that cannot be converted is an ERROR row in the plan, not a traceback in --apply. Per slug:
- every original file moves verbatim to docs/epics/archive/<slug>/ (spec.md gains one header line);
- `done` (every mini-feature in features.json is done): nothing else;
- `open`: docs/epics/<slug>/epic.md and slices/<id>.md are generated from spec.md, contract.md
  and features.json (Problem -> Request, Goal -> Description, mini-feature -> capability group,
  @sN scenario -> SN TODO story + TSN with the literal text, FR/SC and (smoke) tags dropped).
  Both scenario grammars are read: `- **@sN (tag)** Given …` and `- @sN **(tag)** Given …`.
  The epic folder is built in a temp dir and renamed into place, so a failure leaves nothing behind.
Idempotent: a slug already under docs/epics/archive/ with no docs/specs/<slug>/ is skipped.
"""
import argparse
import json
import re
import shutil
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ARCHIVE_HEADER = "<!-- archived from docs/specs/{slug}/ by migrate.py; source=migrated; never rendered -->\n"
HEADING = re.compile(r"^## (?:MF(\d+) — |(\d+)\. )(\S+)")
SCENARIO = re.compile(r"^- (?:\*\*)?@s(\d+)\b(.*)$")
TAGS = re.compile(r"^\s*(?:\*\*)?(?:\s*[(\[][^)\]]*[)\]])*(?:\*\*)?\s*")  # **(smoke)**, [FR-001], …


def status(spec):
    data = json.loads((spec / "features.json").read_text(encoding="utf-8"))
    items = data.get("mini_features") or []
    return ("done" if items and all(m.get("status") == "done" for m in items) else "open"), items


def section(text, title):
    m = re.search(rf"^## {re.escape(title)}\b.*?\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1).strip() if m else "TODO"


def scenarios(contract):
    """{mini-feature number: (name, [(n, [lines])])} from contract.md."""
    groups, current = {}, None
    for line in contract.splitlines():
        h = HEADING.match(line)
        if h:
            current = groups.setdefault(int(h.group(1) or h.group(2)), (h.group(3), []))
            continue
        if line.startswith("## "):
            current = None
            continue
        s = SCENARIO.match(line)
        if s and current:
            current[1].append((int(s.group(1)), [TAGS.sub("", s.group(2), count=1)]))
        elif current and current[1] and line.startswith("  ") and line.strip():
            current[1][-1][1].append(line.strip())
        elif not line.strip() or line.startswith(("-", "#")):
            pass
    return groups


def render_open(spec, slug, items):
    """{relative path: content} for docs/epics/<slug>/; reads only, writes nothing."""
    text = (spec / "spec.md").read_text(encoding="utf-8")
    title = re.sub(r"\s+—\s+Spec$", "", (re.search(r"^# (.*)$", text, re.M) or [None, slug])[1])
    groups = scenarios((spec / "contract.md").read_text(encoding="utf-8")) if (spec / "contract.md").exists() else {}
    head = f"<!-- migrated from docs/specs/{slug}/ at {datetime.now(timezone.utc):%Y-%m-%dT%H:%M:%SZ}; source=migrated; originals in docs/epics/archive/{slug}/ -->\n"
    rows, stories, acs, tss = [], [], [], []
    by_id = {}
    for mf in items:
        name, cases = groups.get(int(mf.get("id", 0)), (mf.get("name", f"mf{mf.get('id')}"), []))
        ids = [n for n, _ in cases]
        by_id[mf.get("id")] = (mf.get("name") or name, ids)
        rows.append(f"| {mf.get('name') or name} | — | {', '.join(f'S{n}' for n in ids) or '—'} |")
        stories.append(f"### {mf.get('name') or name}")
        for n, lines in cases:
            stories.append(f"- **S{n}** TODO: write the story for TS{n}")
            acs.append(f"- **S{n}** TODO: one observable outcome for TS{n}")
            # Cross-references to other scenarios follow the rename (@s17 -> TS17).
            tss.append(f"- **TS{n}** " + re.sub(r"@s(\d+)", r"TS\1", "\n  ".join(lines)))
    body = [head + f"# {slug} — {title}", "## Request", section(text, "Problem"), "## Description", section(text, "Goal"),
            "## Capability groups", "| Group | Tracker | Stories |\n| --- | --- | --- |\n" + "\n".join(rows),
            "## User Stories", "\n".join(stories), "## Acceptance Criteria", "\n".join(acs),
            "## Test Scenarios", "\n".join(tss)]
    files = {"epic.md": "\n\n".join(body) + "\n"}
    for mf in items:
        name, ids = by_id[mf.get("id")]
        refs = ", ".join(f"S{n}" for n in ids) or "—"
        files[f"slices/{mf.get('id')}.md"] = (
            f"{head}# Slice {mf.get('id')} — mixed: {name}\n\n- Layer: mixed\n- Capability group: {name}\n"
            f"- Stories covered: {refs}\n- Status: {mf.get('status', 'todo')}\n\n## Expected behaviour\n"
            f"TODO: see docs/epics/archive/{slug}/contract.md.\n\n## Tests\n"
            + "".join(f"- TS{n}\n" for n in ids))
    return files


def write_atomically(files, out):
    """Build the folder next to its target, then rename it into place."""
    tmp = Path(tempfile.mkdtemp(prefix=f".{out.name}.", dir=out.parent))
    try:
        for rel, content in files.items():
            (tmp / rel).parent.mkdir(parents=True, exist_ok=True)
            (tmp / rel).write_text(content, encoding="utf-8")
        tmp.rename(out)
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=".")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("slugs", nargs="*")
    args = ap.parse_args()
    root = Path(args.root)
    specs, epics = root / "docs" / "specs", root / "docs" / "epics"
    slugs = args.slugs or (sorted(p.name for p in specs.iterdir() if p.is_dir()) if specs.is_dir() else [])
    if not slugs:
        print("nothing to migrate: no docs/specs/ folders")
        return 0
    print(f"{'slug':<28} {'status':<7} {'action':<16} files")
    errors = 0
    for slug in slugs:
        spec, archive = specs / slug, epics / "archive" / slug
        if not spec.is_dir():
            print(f"{slug:<28} {'-':<7} {'skip (migrated)' if archive.is_dir() else 'skip (missing)':<16} -")
            continue
        if archive.exists() or (epics / slug).exists():
            print(f"{slug:<28} {'-':<7} {'CONFLICT':<16} docs/epics/ already has {slug}; resolve by hand")
            errors += 1
            continue
        try:
            state, items = status(spec)
        except (OSError, ValueError) as e:
            print(f"{slug:<28} {'?':<7} {'ERROR':<16} features.json: {e}")
            errors += 1
            continue
        try:
            files = render_open(spec, slug, items) if state == "open" else {}
        except (OSError, ValueError, KeyError, TypeError, AttributeError) as e:
            print(f"{slug:<28} {state:<7} {'ERROR':<16} {type(e).__name__}: {e}")
            errors += 1
            continue
        count = sum(1 for p in spec.rglob("*") if p.is_file())
        print(f"{slug:<28} {state:<7} {'archive' if state == 'done' else 'archive + epic':<16} {count}")
        if not args.apply:
            continue
        if files:
            epics.mkdir(parents=True, exist_ok=True)
            write_atomically(files, epics / slug)
        archive.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(spec), str(archive))
        spec_md = archive / "spec.md"
        if spec_md.exists():
            spec_md.write_text(ARCHIVE_HEADER.format(slug=slug) + spec_md.read_text(encoding="utf-8"), encoding="utf-8")
    if args.apply and specs.is_dir() and not any(specs.iterdir()):
        specs.rmdir()
    if not args.apply and slugs:
        print("plan only; rerun with --apply to write")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
