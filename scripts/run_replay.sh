#!/usr/bin/env bash
set -euo pipefail
LOG="${1:-sample_logs/rotate_fail.log}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT"
dart pub get >/dev/null
dart run tool/golden_replay.dart "$LOG" -v
