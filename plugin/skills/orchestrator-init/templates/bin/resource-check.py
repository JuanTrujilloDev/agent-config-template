#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyyaml"]
# ///
"""Pre-dispatch resource check for this machine (macOS and Linux: reads sysctl and
vm_stat, or /proc/meminfo).

Reports free memory, load average, heavy processes with RSS, and the local
workloads currently recorded as running in state/*.yaml. Then
decides whether a new dispatch fits:

  --kind remote   work that only reads code and calls a hosted model: always fits
  --kind local    runs a suite, browser, build or service on this machine:
                  needs --need MB free (default 2500), no other local run for the
                  same --project, and fewer than --max-local local runs machine-wide

Exit 0 = dispatch, 1 = wait (reason printed), 2 = could not measure.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import default_root, list_state_files, load_state  # noqa: E402

HEAVY = re.compile(
    r"(node|electron|chrom|playwright|cargo|rustc|pytest|vitest|jest|wrangler|workerd|postgres|colima|docker|qemu|"
    r"python\S*\s+-m\s+(pytest|unittest)|uv run)",
    re.IGNORECASE,
)
LOCAL_KINDS = {"execute", "fix", "review", "diagnosis", "publication", "closeout", "design"}


def sh(cmd: List[str]) -> str:
    try:
        return subprocess.run(cmd, capture_output=True, text=True, check=False).stdout
    except OSError as e:  # command missing: exit 2 (could not measure), never 1 (wait)
        print(f"could not run {cmd[0]}: {e}")
        sys.exit(2)


def memory_mb() -> Tuple[int, int]:
    """(total MB, free-ish MB). Linux: MemTotal, MemAvailable. macOS: free + inactive + speculative pages."""
    try:
        kb = dict(re.findall(r"^(MemTotal|MemAvailable):\s+(\d+) kB", Path("/proc/meminfo").read_text(), re.M))
    except OSError:
        kb = {}
    if "MemTotal" in kb:
        return int(kb["MemTotal"]) // 1024, int(kb.get("MemAvailable", 0)) // 1024
    total = int(sh(["sysctl", "-n", "hw.memsize"]).strip() or 0) // (1024 * 1024)
    out = sh(["vm_stat"])
    m = re.search(r"page size of (\d+) bytes", out)
    page = int(m.group(1)) if m else 16384
    vals: Dict[str, int] = {}
    for line in out.splitlines():
        mm = re.match(r"^(Pages [a-z ]+?):\s+(\d+)\.", line)
        if mm:
            vals[mm.group(1)] = int(mm.group(2))
    free_pages = vals.get("Pages free", 0) + vals.get("Pages inactive", 0) + vals.get("Pages speculative", 0)
    return total, free_pages * page // (1024 * 1024)


def load_avg() -> Tuple[float, float, float]:
    try:
        return os.getloadavg()
    except OSError:
        return (0.0, 0.0, 0.0)


def heavy_processes(limit: int = 15) -> List[Tuple[int, str]]:
    out = sh(["ps", "-axo", "rss=,command="])
    procs: List[Tuple[int, str]] = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(None, 1)
        if len(parts) != 2:
            continue
        rss_kb, cmd = parts
        if HEAVY.search(cmd) and "resource-check" not in cmd:
            procs.append((int(rss_kb) // 1024, cmd[:90]))
    procs.sort(reverse=True)
    return procs[:limit]


def local_runs(root: Path) -> List[Tuple[str, str, str]]:
    """(task, project, run id) for running local-kind runs in tasks with a repo path."""
    out = []
    for p in list_state_files(root):
        try:
            d = load_state(p)
        except Exception:  # noqa: BLE001
            continue
        if not d.get("repo"):
            continue
        for r in d.get("runs") or []:
            if r.get("state") == "running" and r.get("kind") in LOCAL_KINDS and r.get("local", True):
                out.append((str(d.get("task")), str(d.get("project") or ""), str(r.get("id"))))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=default_root())
    ap.add_argument("--kind", choices=["local", "remote"], default="local")
    ap.add_argument("--need", type=int, default=2500, help="MB of free memory a local dispatch needs")
    ap.add_argument("--project", help="project key of the dispatch, for the same-project rule")
    ap.add_argument("--max-local", type=int, default=2, help="max local workloads machine-wide")
    ap.add_argument("--max-load", type=float, default=None,
                    help="1-minute load average above which local dispatch waits (default: core count)")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    total, free = memory_mb()
    if total == 0:
        print("could not read memory (/proc/meminfo or sysctl hw.memsize)")
        return 2
    l1, l5, l15 = load_avg()
    cores = os.cpu_count() or 8
    max_load = args.max_load if args.max_load is not None else float(cores)
    procs = heavy_processes()
    running = local_runs(args.root.resolve())

    if not args.quiet:
        print(f"memory: {free} MB free-ish of {total} MB")
        print(f"load: {l1:.2f} {l5:.2f} {l15:.2f} (cores {cores})")
        print("heavy processes (MB RSS):")
        for rss, cmd in procs or []:
            print(f"  {rss:6d}  {cmd}")
        if not procs:
            print("  none")
        print(f"local runs recorded as running: {len(running)}")
        for task, project, rid in running:
            print(f"  {task} [{project}] {rid}")

    if args.kind == "remote":
        print("fits: remote-only work")
        return 0

    reasons = []
    if free < args.need:
        reasons.append(f"free memory {free} MB < needed {args.need} MB")
    if l1 > max_load:
        reasons.append(f"load {l1:.2f} > {max_load:.2f}")
    if len(running) >= args.max_local:
        reasons.append(f"{len(running)} local runs already running (max {args.max_local})")
    if args.project and any(p == args.project for _, p, _ in running):
        reasons.append(f"a local run for project {args.project!r} is already running")

    if reasons:
        print("wait: " + "; ".join(reasons))
        return 1
    print("fits: local dispatch")
    return 0


if __name__ == "__main__":
    sys.exit(main())
