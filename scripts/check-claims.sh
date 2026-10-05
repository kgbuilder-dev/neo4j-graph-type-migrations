#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

failures=0

expect_fail() {
  local desc="$1"; shift
  local out
  if out=$(cy "$@" 2>&1); then
    echo "FAIL  $desc (expected an error, the statement succeeded)"
    failures=$((failures + 1))
  else
    echo "PASS  $desc (error, as expected)"
    echo "$out" | sed 's/^/        /'
  fi
}

expect_ok() {
  local desc="$1"; shift
  local out
  if out=$(cy "$@" 2>&1); then
    echo "PASS  $desc (succeeded, as expected)"
  else
    echo "FAIL  $desc (expected success)"
    echo "$out" | sed 's/^/        /'
    failures=$((failures + 1))
  fi
}

expect_value() {
  local desc="$1" expected="$2" query="$3"
  local v
  v=$(cy "$query" | tail -n 1 | tr -d '[:space:]')
  if [ "$v" = "$expected" ]; then
    echo "PASS  $desc ($v)"
  else
    echo "FAIL  $desc (expected $expected, got $v)"
    failures=$((failures + 1))
  fi
}

with_starting_data() {
  fresh_db "$1"
  nm migrate --target V1 > /dev/null
  cy < seed/after-V1.cypher
}

echo "== Claim 1: SET refuses data that breaks the new graph type"
with_starting_data claim1
expect_fail "SET with Talk.level NOT NULL while one talk has no level" \
  "CYPHER 25 ALTER CURRENT GRAPH TYPE SET { (:Talk => {title :: STRING NOT NULL, level :: STRING NOT NULL}) }"

echo "== Claim 2: SET replaces constraints created before it"
with_starting_data claim2
cy "CREATE CONSTRAINT person_name_unique IF NOT EXISTS FOR (p:Person) REQUIRE p.name IS UNIQUE"
expect_value "constraint exists before SET" 1 \
  "SHOW CONSTRAINTS YIELD name WHERE name = 'person_name_unique' RETURN count(*)"
cy "CYPHER 25 ALTER CURRENT GRAPH TYPE SET { (:Talk => {title :: STRING NOT NULL}) }"
expect_value "constraint gone after a second SET" 0 \
  "SHOW CONSTRAINTS YIELD name WHERE name = 'person_name_unique' RETURN count(*)"

echo "== Claim 3: ADD cannot extend an existing element type; ALTER redefines it completely"
with_starting_data claim3
expect_fail "ADD a property to the existing Person type" \
  "CYPHER 25 ALTER CURRENT GRAPH TYPE ADD { (:Person => {name :: STRING NOT NULL, nickname :: STRING}) }"
expect_fail "Person with an integer email under the starting model (email :: STRING)" \
  "CREATE (:Person {name: 'Test', email: 42})"
cy "CYPHER 25 ALTER CURRENT GRAPH TYPE ALTER { (:Person => {name :: STRING NOT NULL}) }"
expect_ok "same write after ALTER restated Person without email" \
  "CREATE (:Person {name: 'Test', email: 42})"
cy "CYPHER 25 ALTER CURRENT GRAPH TYPE ALTER { (:Person => {name :: STRING}) }"
expect_ok "Person without name after ALTER left out NOT NULL" \
  "CREATE (:Person {nickname: 'anonymous'})"

echo "== Claim 4: DROP removes the rule and keeps the data"
with_starting_data claim4
cy "CYPHER 25 ALTER CURRENT GRAPH TYPE DROP { ()-[:SCHEDULED_AT =>]->() }"
expect_value "SCHEDULED_AT relationships still in the database" 7 \
  "MATCH ()-[s:SCHEDULED_AT]->() RETURN count(s)"

echo "== Claim 5: schema change and data change cannot share a transaction"
with_starting_data claim5
expect_fail "graph type DROP and DELETE in one explicit transaction" \
  < <(printf ':begin\nCYPHER 25 ALTER CURRENT GRAPH TYPE DROP { ()-[:SCHEDULED_AT =>]->() };\nMATCH ()-[s:SCHEDULED_AT]->() DELETE s;\n:commit\n')

echo "== Claim 6: after the contract step, old writers are no longer checked"
with_starting_data claim6
nm migrate --target V2 > /dev/null
cy < seed/after-V2.cypher
nm migrate > /dev/null
expect_ok "write an old-shape SCHEDULED_AT without room or slot" \
  "MATCH (t:Talk {title: 'Graph types in practice'}), (e:Event {name: 'GraphConf Wroclaw'}) CREATE (t)-[:SCHEDULED_AT]->(e)"
expect_fail "write a Session without start (declared rule)" \
  "CREATE (:Session {recording: 'n/a'})"

echo "== Claim 7: V4 can be rerun after a partial failure without duplicating sessions"
with_starting_data claim7
nm migrate --target V4 > /dev/null
before=$(cy "MATCH (s:Session) RETURN count(s)" | tail -n 1 | tr -d '[:space:]')
cy < migrations/V4__move_schedule_to_sessions.cypher
expect_value "session count unchanged after running V4 a second time" "$before" \
  "MATCH (s:Session) RETURN count(s)"
expect_value "room count after rerun (one Room per name)" 4 \
  "MATCH (r:Room) RETURN count(r)"

echo
if [ "$failures" -eq 0 ]; then
  echo "All claims hold."
else
  echo "$failures claim check(s) failed."
  exit 1
fi
