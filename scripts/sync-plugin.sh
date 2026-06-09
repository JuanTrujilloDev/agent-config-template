#!/usr/bin/env bash
# Deprecated shim — superseded by scripts/build.sh (v0.5.0).
# Kept so older references and any cached CI keep working.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build.sh" "$@"
