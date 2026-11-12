#!/bin/bash
# Draws every lock screen scenario off screen into a folder, for looking at.
#   tests/run.sh [outdir]
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
out=${1:-$(mktemp -d)}
mkdir -p "$out"
export QT_QPA_PLATFORM=offscreen
for s in dark light typing typing-light error error-light checking many many-light empty empty-light limits-only sessions-only two two-light charging finger finger-typing intro shake roll nomusic; do
  timeout 30 qml6 -I "$here/tests/mock" "$here/tests/Harness.qml" -- "$out" "$s" 2>&1 | grep -v quickshell-coreplugin || true
done
count=$(ls "$out"/*.png 2>/dev/null | wc -l)
echo "$count frames in $out"
