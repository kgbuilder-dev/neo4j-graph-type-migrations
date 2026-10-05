#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

docker run -d --name "$CONTAINER" -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH="neo4j/$NEO4J_PASSWORD" \
  -e NEO4J_ACCEPT_LICENSE_AGREEMENT=yes \
  "${NEO4J_IMAGE:-neo4j:2026.09.0-enterprise}" > /dev/null

for _ in $(seq 1 90); do
  if cy "RETURN 1" > /dev/null 2>&1; then
    cy "CALL dbms.components() YIELD versions, edition RETURN versions[0] AS version, edition"
    exit 0
  fi
  sleep 2
done
echo "Neo4j did not start" >&2
docker logs "$CONTAINER" | tail -50 >&2
exit 1
