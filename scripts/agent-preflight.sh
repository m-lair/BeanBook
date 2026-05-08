#!/usr/bin/env bash
set -euo pipefail

missing=0

fail() {
  echo "$1" >&2
  missing=1
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    fail "missing required file: $path"
  fi
}

require_file "AGENTS.md"
require_file "docs/architecture.md"
require_file "docs/branding.md"
require_file "docs/design.md"
require_file "docs/quality.md"
require_file "docs/agent-workflow.md"
require_file "BeanBook.xcodeproj/project.pbxproj"
require_file "scripts/validate-catalog.js"

if ! grep -q "docs/agent-workflow.md" AGENTS.md; then
  fail "AGENTS.md does not link docs/agent-workflow.md"
fi

if ! grep -q "docs/quality.md" AGENTS.md; then
  fail "AGENTS.md does not link docs/quality.md"
fi

color_violations="$(
  rg -n "Color\\(hex:" BeanBook --glob "*.swift" \
    --glob "!BeanBook/Shared/Theme/**" \
    --glob "!BeanBook/Shared/Extensions/Color+Hex.swift" \
    --glob "!BeanBook/Shared/Extensions/RoastLevel+Swatch.swift" || true
)"
if [[ -n "$color_violations" ]]; then
  echo "$color_violations" >&2
  fail "hardcoded Color(hex:) found outside approved theme/shared semantic files"
fi

if ! node scripts/validate-catalog.js; then
  fail "catalog validation failed"
fi

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "Agent preflight passed."
