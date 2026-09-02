# MF1 output-style (@s1..@s4, @s9) — banner + parity cases through the rendered hook.
GATED_CONCISE='mode: gated | output: concise — say "just go" or "explain more" to override this session'
V081_GATED="mode: gated — say 'just go' for autonomous"

# @s1
hook_case "@s1 no prefs" "$CODING" "$GATED_CONCISE"
# @s2
hook_case "@s2 autonomous+detailed" "$CODING" \
  'mode: autonomous | output: detailed — say "gate me" or "be brief" to override this session' \
  "$(printf 'autonomy_mode=autonomous\noutput_style=detailed')"
hook_case "@s2 gated+balanced" "$CODING" \
  'mode: gated | output: balanced — say "just go" or "explain more" to override this session' \
  "output_style=balanced"
hook_case "@s2 gated+terse" "$CODING" \
  'mode: gated | output: terse — say "just go" or "explain more" to override this session' \
  "output_style=terse"
hook_case "@s2 autonomous+terse" "$CODING" \
  'mode: autonomous | output: terse — say "gate me" or "be brief" to override this session' \
  "$(printf 'autonomy_mode=autonomous\noutput_style=terse')"
# @s3 — unrecognized value → v0.8.1 banner, value never echoed
hook_case "@s3 unrecognized" "$CODING" "$V081_GATED" "output_style=verbose"
check "@s3 value not leaked" "0" "$(printf '%s%s' "$CORE_OUT" "$OUT" | grep -c verbose)"
# injection payloads in prefs → fixed strings only
hook_case "inject unrecognized" "$CODING" "$V081_GATED" \
  "$(printf 'autonomy_mode=gated\noutput_style=concise; echo PWNED')"
check "inject not leaked" "0" "$(printf '%s%s' "$CORE_OUT" "$OUT" | grep -c PWNED)"
# garbled/unreadable prefs → fallback banner, exit 0, silent
hook_case "garbled prefs" "$CODING" "$GATED_CONCISE" "$(printf '\x00\xff\xfe\n\x01garbage')"
# @s4 — non-coding prompt → no output
hook_case "@s4 non-coding" "$NONCODING" ""
check "@s4 empty output" "" "$OUT"
