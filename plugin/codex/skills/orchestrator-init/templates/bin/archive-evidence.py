#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyyaml"]
# ///
"""Move a run's evidence directory out of the repo into ~/orchestrator-artifacts/<task>/<run-id>/.

Creates <dest>.tar next to the moved directory, computes its SHA-256, writes
manifest.json inside the destination (per-file size and sha256), prints the
destination and hash, and with --state records them on the run in the state file.

Never deletes. If the destination exists, a numeric suffix is added. Refuses to
move a directory that contains git-tracked files unless --allow-tracked is given.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path
from typing import Dict, List

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import (  # noqa: E402
    StateError, default_root, die, find_run, load_state, save_state, state_path, touch_updated,
)


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def tracked_files(src: Path) -> List[str]:
    try:
        out = subprocess.run(
            ["git", "-C", str(src), "ls-files", "--error-unmatch", "--", "."],
            capture_output=True, text=True, check=False,
        )
    except FileNotFoundError:
        return []
    if out.returncode != 0:
        return []
    return [line for line in out.stdout.splitlines() if line.strip()]


def unique_dest(base: Path) -> Path:
    if not base.exists():
        return base
    n = 2
    while True:
        cand = base.with_name(f"{base.name}-{n}")
        if not cand.exists():
            return cand
        n += 1


def build_manifest(dest: Path) -> Dict:
    files = []
    total = 0
    for p in sorted(dest.rglob("*")):
        if p.is_file() and p.name != "manifest.json":
            size = p.stat().st_size
            total += size
            files.append({"path": str(p.relative_to(dest)), "size": size, "sha256": sha256_file(p)})
    return {"files": files, "file_count": len(files), "total_bytes": total}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=default_root())
    ap.add_argument("--task", required=True, help="task id, used for the destination folder and --state")
    ap.add_argument("--run", required=True, help="run id, used for the destination folder and --state")
    ap.add_argument("source", type=Path, help="evidence directory to move")
    ap.add_argument("--store", type=Path, default=Path("~/orchestrator-artifacts"),
                    help="artifact store root (default ~/orchestrator-artifacts)")
    ap.add_argument("--allow-tracked", action="store_true", help="move even if files are tracked by git")
    ap.add_argument("--state", action="store_true", help="record path and sha256 on the run in the state file")
    args = ap.parse_args()

    # Both ids become folder names under the store: validate before anything moves.
    try:
        spath = state_path(args.root.resolve(), args.task)
    except StateError as e:
        die(str(e))
    if "/" in args.run or args.run.strip() in ("", ".", ".."):
        die(f"--run must be a plain name without '/', got {args.run!r}")

    src = args.source.expanduser().resolve()
    if not src.is_dir():
        die(f"{src} is not a directory")
    store = args.store.expanduser().resolve()
    if src == store or store in src.parents:
        die(f"{src} is already inside the artifact store")

    tracked = tracked_files(src)
    if tracked and not args.allow_tracked:
        die(f"{len(tracked)} git-tracked file(s) under {src} (first: {tracked[0]}); "
            "pass --allow-tracked to move anyway (then git rm them separately)")

    dest = unique_dest(store / args.task / args.run)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dest))

    manifest = build_manifest(dest)
    manifest.update({"task": args.task, "run": args.run, "source": str(src), "destination": str(dest)})
    (dest / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    tar_path = dest.with_suffix(".tar")
    if tar_path.exists():
        tar_path = unique_dest(tar_path)
    with tarfile.open(tar_path, "w") as tf:
        tf.add(dest, arcname=dest.name)
    digest = sha256_file(tar_path)

    print(f"moved: {src} -> {dest}")
    print(f"tar: {tar_path}")
    print(f"sha256: {digest}")
    print(f"files: {manifest['file_count']} ({manifest['total_bytes']} bytes)")

    if args.state:
        try:
            data = load_state(spath)
            run = find_run(data, args.run)
            if run is None:
                raise StateError(f"run {args.run!r} not found in {spath.name}")
            home = str(Path.home())
            shown = str(dest).replace(home, "~", 1) if str(dest).startswith(home) else str(dest)
            run["evidence"] = {"path": shown, "sha256": digest, "tar": str(tar_path).replace(home, "~", 1)}
            touch_updated(data)
            save_state(spath, data)
            print(f"state: recorded evidence on run {args.run} in {spath.name}")
        except StateError as e:
            die(str(e))
    return 0


if __name__ == "__main__":
    sys.exit(main())
