#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

fresh_db releases

echo "== Release 1: baseline (V1) + demo data"
nm migrate --target V1
cy < seed/after-V1.cypher

echo "== Release 2: Organization (V2) + demo data"
nm migrate --target V2
cy < seed/after-V2.cypher

echo "== Release 3: expand + migrate (V3-V4), then check before switching readers"
nm migrate --target V4
check_dir tests/after-V4

echo "== Release 4: contract (V5-V6) and employer-data removal (V7-V8)"
nm migrate
check_dir tests/final

nm info
