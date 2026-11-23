# v0.13.1 release: every version pin says 0.13.1 and the README sha256 matches bootstrap.sh.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v0131-release.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V0131_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

for m in plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/plugin.json codex/.codex-plugin/plugin.json; do
  grep_case "v0.13.1 $m at 0.13.1" "$ROOT/$m" '"version": *"0\.13\.1"'
done
for f in setup.sh plugin/setup.sh; do
  grep_case "v0.13.1 $f TEMPLATE_VERSION 0.13.1" "$ROOT/$f" '^TEMPLATE_VERSION="0\.13\.1"$'
done
grep_case "v0.13.1 bootstrap.sh DEFAULT_REF v0.13.1" "$ROOT/bootstrap.sh" '^DEFAULT_REF="v0\.13\.1"$'
for f in README.md docs/install/README.md; do
  grep_case "v0.13.1 $f install command pins v0.13.1" "$ROOT/$f" 'agent-config-template/v0\.13\.1/bootstrap\.sh'
done
V131_SHA=$(shasum -a 256 "$ROOT/bootstrap.sh" | cut -d' ' -f1)
grep_case "v0.13.1 README sha256 matches bootstrap.sh" "$ROOT/README.md" "^\`bootstrap\.sh\` at \`v0\.13\.1\`: sha256 \`$V131_SHA\`"
check "v0.13.1 README: v0.13.1 is the first release section" "## v0.13.1 — orchestrator-init and architect model pick" "$(grep -m1 '^## v0\.' "$ROOT/README.md")"
V131_UG=$(section "$ROOT/docs/upgrade-guide.md" '^## Upgrading from v0\.13\.0 to v0\.13\.1')
for t in 'orchestrator-init' 'architect' 'Who needs to act' 'update-config'; do
  grep_case "v0.13.1 upgrade guide names $t" <(printf '%s\n' "$V131_UG") "$t"
done

[ -n "${V0131_ALONE:-}" ] && exit $FAIL
