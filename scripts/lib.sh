#!/usr/bin/env bash
set -euo pipefail

export NEO4J_PASSWORD="${NEO4J_PASSWORD:-local-demo-password}"
CONTAINER="${NEO4J_CONTAINER:-graph-type-migrations-neo4j}"
DB="${DB:-neo4j}"

nm() {
  local command="$1"; shift
  neo4j-migrations -a bolt://localhost:7687 -u neo4j --password:env NEO4J_PASSWORD \
    -d "$DB" --location "file:$PWD/migrations" --cypher-version CYPHER_25 "$@" "$command"
}

cy() {
  docker exec -i "$CONTAINER" cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -d "$DB" --format plain "$@"
}

check_dir() {
  local failed=0
  for f in "$1"/*.cypher; do
    local v
    v=$(cy < "$f" | tail -n 1 | tr -d '[:space:]')
    if [ "$v" = "0" ]; then
      echo "PASS  $(basename "$f")"
    else
      echo "FAIL  $(basename "$f") -> $v violations"
      failed=1
    fi
  done
  return "$failed"
}

fresh_db() {
  DB=system cy "CREATE OR REPLACE DATABASE \`$1\` WAIT" > /dev/null
  DB="$1"
}
