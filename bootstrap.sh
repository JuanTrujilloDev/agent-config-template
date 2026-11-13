#!/bin/sh
# agent-config-template bootstrap: install the template into the current git repo in one command.
# Clones the template at a pinned ref, previews the change plan (writes nothing), asks before applying.
# No telemetry; the clone is the only network call. Usage: see usage() below, or run with --help.
# The whole script is one function call at the bottom, so `curl ... | sh` never runs a half-read file.

# RELEASE STEP: set this to the tag the file ships in (e.g. v0.12.0) before tagging; README pins its sha256.
DEFAULT_REF="main"
DEFAULT_SOURCE="https://github.com/JuanTrujilloDev/agent-config-template.git"

usage() {
  cat <<'EOF'
Usage: curl -fsSL <raw bootstrap.sh URL at a tag> | sh -s -- [options]
       sh bootstrap.sh [options]

Run inside the git repository you want to set up (any subfolder works; the repo root is used).

  --host <list>     hosts to render: claude, cursor, codex (grok = claude + AGENTS.md); comma list.
                    Default: TARGET_HOSTS from answers.env, else claude.
  --ref <tag>       template release to install. Default: the release this script ships in.
  --answers <file>  answers file. Default: ./answers.env; when absent, one is generated from the
                    template defaults and written to answers.env on apply.
  --legacy          on apply, bring a repo rendered before agent-config.lock.json under the lock
                    (setup.sh --merge --legacy). Only for unedited template output; needs the
                    repo's answers.env.
  --prune           on apply, also delete the OBSOLETE files the preview lists (setup.sh --prune).
  --force           run on a working tree with uncommitted changes.
  --source <url>    template git URL (a mirror or a local file:// repo). Default: GitHub.
  -h, --help        show this help.

Needs git, python3 and bash. Apply runs setup.sh --merge: missing files are added, STALE-MANAGED
files (unedited since the last render) are refreshed, everything else is kept.
EOF
}

die() { printf 'bootstrap: %s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 is required but not on PATH"; }

main() {
  ref="$DEFAULT_REF"; source_url="$DEFAULT_SOURCE"; host=""; answers=""; force=""; legacy=""; prune=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --host|--ref|--answers|--source)
        [ $# -ge 2 ] || die "$1 needs a value"
        case "$1" in
          --host) host="$2" ;; --ref) ref="$2" ;; --answers) answers="$2" ;; --source) source_url="$2" ;;
        esac
        shift 2 ;;
      --force) force=1; shift ;;
      --legacy) legacy=1; shift ;;
      --prune) prune=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) usage >&2; die "unknown option: $1" ;;
    esac
  done

  need git; need python3; need bash
  if [ -n "$answers" ]; then
    case "$answers" in /*) ;; *) answers="$PWD/$answers" ;; esac
    [ -f "$answers" ] || die "answers file not found: $answers"
  fi
  root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository; cd into the repo you want to set up"
  cd "$root" || die "cannot enter $root"
  if [ -z "$force" ] && [ -n "$(git status --porcelain)" ]; then
    die "the working tree has uncommitted changes; commit or stash them first, or pass --force"
  fi

  tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-config-bootstrap.XXXXXX") || die "cannot create a temp folder"
  trap 'rm -rf "$tmp"' EXIT
  trap 'exit 130' INT TERM

  printf 'Cloning %s at %s\n' "$source_url" "$ref"
  GIT_TERMINAL_PROMPT=0 git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$ref" \
    "$source_url" "$tmp/template" </dev/null || die "cannot clone $source_url at $ref"
  [ -f "$tmp/template/setup.sh" ] || die "$source_url at $ref has no setup.sh"

  generated=""
  [ -n "$answers" ] || [ ! -f answers.env ] || answers="$root/answers.env"
  if [ -z "$answers" ]; then
    [ -z "$legacy" ] || die "--legacy needs the answers.env this repo was rendered with; none found"
    generated="$tmp/answers.env"
    branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
    write_default_answers "$tmp/template/template.config.yaml" "$(basename "$root")" "${host:-claude}" "${branch#*/}" \
      >"$generated" || die "cannot read the template defaults"
    answers="$generated"
    echo "answers: none in this repo; using the template defaults (written to answers.env on apply)"
  else
    printf 'answers: %s\n' "${answers#"$root"/}"
  fi

  set -- --target . --answers "$answers"
  if [ -n "$host" ]; then set -- "$@" --host "$host"; fi
  echo ""
  bash "$tmp/template/setup.sh" "$@" --abort </dev/null >"$tmp/plan.txt" 2>&1 \
    || { cat "$tmp/plan.txt"; die "preview failed; nothing was written"; }
  cat "$tmp/plan.txt"
  # Unedited template files (hash matches the lock) are refreshed; edited and legacy ones are kept.
  stale=$(awk '$1 == "STALE-MANAGED" && NF == 2 { printf "%s%s", sep, $2; sep = "," }' "$tmp/plan.txt")
  echo ""
  echo "Apply adds the ADD files, merges settings.json, refreshes every STALE-MANAGED file and keeps all others."
  printf 'Apply? (y/N) '
  reply=""
  # AGENT_CONFIG_TTY: test seam for the answer source; users never need it.
  read -r reply 2>/dev/null <"${AGENT_CONFIG_TTY:-/dev/tty}" || reply=""
  case "$reply" in
    y|Y|yes|Yes|YES) ;;
    *) echo "Not applied; nothing was written."; return 0 ;;
  esac

  if [ -n "$legacy" ]; then set -- "$@" --legacy; fi
  if [ -n "$prune" ]; then set -- "$@" --prune; fi
  if [ -n "$stale" ]; then set -- "$@" --overwrite-files "$stale"; fi
  bash "$tmp/template/setup.sh" "$@" --merge </dev/null || die "apply failed; review git status"
  if [ -n "$generated" ] && [ ! -e answers.env ]; then
    cp "$generated" answers.env || die "cannot write answers.env"
    echo "  + answers.env (template defaults: run /setup-template, or edit it and re-run, to calibrate)"
  fi
  echo ""
  echo "Done. Review with git status and git diff, then commit on a branch."
}

# answers.env from template.config.yaml: each variable's default, `when:` clauses honoured,
# project_name from the repo folder, default_branch from origin/HEAD when known.
write_default_answers() {
  python3 - "$@" <<'PY'
import re, sys

config, name, hosts, branch = sys.argv[1:5]
variables, current = [], None
for line in open(config, encoding="utf-8"):
    m = re.match(r"\s+- name:\s*(\w+)", line)
    if m:
        current = {"name": m.group(1)}
        variables.append(current)
        continue
    m = re.match(r'\s+(default|default_from|when):\s*(?:"([^"]*)"|([^#\n]*))', line)
    if m and current is not None:
        current[m.group(1)] = (m.group(2) if m.group(2) is not None else m.group(3)).strip()

values = {"project_name": name}
if branch:
    values["default_branch"] = branch
lines = []
for var in variables:
    key = var["name"]
    if key == "target_hosts":
        continue
    when = re.fullmatch(r"(\w+)\s*==\s*(\S+)", var.get("when", ""))
    if when and values.get(when.group(1), "").lower() != when.group(2).lower():
        continue
    if key not in values:
        source = var.get("default_from")
        values[key] = re.sub(r"[^a-z0-9]+", "-", values.get(source, "").lower()).strip("-") if source else var.get("default", "")
    lines.append(f"{key}={values[key]}")
print("# Generated by bootstrap.sh from template.config.yaml defaults: a generic profile, not inferred.")
print("# Calibrate it: run /setup-template (Claude Code or Cursor plugin), or edit the values and re-run bootstrap.")
print(f"TARGET_HOSTS={hosts}")
print("\n".join(lines))
PY
}

main "$@"
